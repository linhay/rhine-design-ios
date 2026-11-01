#!/usr/bin/env python3
"""Run prebuilt native tests while changing only one simulator's real text size."""
import argparse
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time


def command(args):
    return subprocess.check_output(args, text=True, stderr=subprocess.STDOUT, timeout=20).strip()


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--device", required=True, help="One already booted task simulator ID")
    parser.add_argument("--derived-data", required=True, type=Path, help="Existing build-for-testing products")
    parser.add_argument("--output", required=True, type=Path, help="A new evidence directory")
    parser.add_argument("--test", choices=["reading", "draft", "both"], default="both")
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    original = command(["xcrun", "simctl", "ui", args.device, "content_size"])
    if original in {"unknown", "unsupported"}:
        raise RuntimeError("System content size is not readable")
    project = Path(__file__).resolve().parents[1] / "RhineExample.xcodeproj"
    tests = {
        "reading": "testLiveSystemSizePreservesBottomAndHistory",
        "draft": "testLiveSystemSizePreservesDraftSelectionAndKeyboard",
    }
    selected_groups = list(tests) if args.test == "both" else [args.test]
    selected = [tests[group] for group in selected_groups]
    maximum = "accessibility-extra-extra-extra-large"
    steps = {
        "reading": [("bottom-maximum", maximum), ("bottom-large", "large"),
                    ("history-maximum", maximum), ("history-large", "large")],
        "draft": [("draft-maximum", maximum), ("draft-large", "large")],
    }
    requests = {step: (group, size) for group in selected_groups for step, size in steps[group]}
    requests.update({f"{group}-baseline": (group, "large") for group in selected_groups})
    bundle = (args.output / "result.xcresult").resolve()
    argv = [
        "xcodebuild", "-project", str(project), "-scheme", "RhineExample",
        "-destination", f"platform=iOS Simulator,id={args.device}",
        "-derivedDataPath", str(args.derived_data.resolve()),
        "-resultBundlePath", str(bundle),
        "-parallel-testing-enabled", "NO", "-test-timeouts-enabled", "YES",
        "-collect-test-diagnostics", "never",
        "-default-test-execution-time-allowance", "150",
        "-maximum-test-execution-time-allowance", "180",
        *[f"-only-testing:RhineExampleUITests/AgentSessionLiveSizingTests/{name}" for name in selected],
        "test-without-building",
    ]
    log = args.output / "test.log"
    records = {"original": original, "selectedTests": selected, "events": [],
               "validationPassed": False, "restored": False}
    result_path = args.output / "system-transitions.json"
    process = None

    def save():
        result_path.write_text(json.dumps(records, ensure_ascii=False, indent=2) + "\n")

    def pid():
        lines = command(["xcrun", "simctl", "spawn", args.device, "launchctl", "list"]).splitlines()
        matches = []
        for line in lines:
            fields = line.split()
            if "io.github.linhay.rhinedesign.example" in line and fields and fields[0].isdigit():
                matches.append(int(fields[0]))
        require(len(matches) == 1 and matches[0] > 0, "Expected exactly one running example app PID")
        return matches[0]

    def validate_results():
        reports = {}
        for kind in ("summary", "tests"):
            report = command(["xcrun", "xcresulttool", "get", "test-results", kind, "--path", str(bundle)])
            (args.output / f"test-{kind}.json").write_text(report + "\n")
            reports[kind] = json.loads(report)
        summary = reports["summary"]
        records["testSummary"] = {key: summary.get(key) for key in
                                  ("result", "totalTestCount", "passedTests", "failedTests",
                                   "skippedTests", "expectedFailures")}

        def walk(nodes):
            for node in nodes:
                yield node
                yield from walk(node.get("children", []))

        nodes = list(walk(reports["tests"].get("testNodes", [])))
        cases = [{"identifier": "/".join(node.get("nodeIdentifier", "").removesuffix("()").split("/")[-2:]),
                  "result": node.get("result")} for node in nodes if node.get("nodeType") == "Test Case"]
        records["testCases"] = cases
        save()
        require(records["testExitCode"] == 0, f"xcodebuild exited {records['testExitCode']}")
        require(summary.get("result") == "Passed"
                and summary.get("totalTestCount") == len(selected)
                and summary.get("passedTests") == len(selected)
                and all(summary.get(key) == 0 for key in ("failedTests", "skippedTests", "expectedFailures")),
                "Every selected test must execute and pass without skips or expected failures")
        expected = {f"AgentSessionLiveSizingTests/{name}" for name in selected}
        require(len(cases) == len(expected) and {case["identifier"] for case in cases} == expected
                and all(case["result"] == "Passed" for case in cases),
                "xcresult does not contain exactly the selected passing test cases")
        require(all(node.get("result") in (None, "Passed") for node in nodes),
                "xcresult contains a failed, skipped, unknown, or retried failing result")

        for group in selected_groups:
            events = [event for event in records["events"] if event["test"] == group]
            transitions = [event for event in events if not event["step"].endswith("-baseline")]
            require([(event["step"], event["readback"]) for event in transitions] == steps[group],
                    f"Missing or out-of-order real system transitions for {group}")
            pids = {event[key] for event in events for key in ("pidBefore", "pidAfter")}
            require(len(pids) == 1 and all(isinstance(value, int) and value > 0 for value in pids),
                    f"App PID must remain nonempty and unchanged throughout {group}")
            for event in transitions:
                previous = "large" if event["requested"] == maximum else maximum
                require(event["readbackBefore"] == previous and event["readback"] == event["requested"],
                        f"No verified real system size transition for {event['step']}")
        records["validationPassed"] = True
        save()

    try:
        command(["xcrun", "simctl", "ui", args.device, "content_size", "large"])
        records["initialReadback"] = command(["xcrun", "simctl", "ui", args.device, "content_size"])
        require(records["initialReadback"] == "large", "Initial system size must read back as large")
        save()
        environment = os.environ.copy()
        environment["TEST_RUNNER_RHINE_LIVE_SIZE_DRIVER"] = "1"
        with log.open("w") as output:
            process = subprocess.Popen(argv, stdout=output, stderr=subprocess.STDOUT,
                                       env=environment, start_new_session=True)
            start, seen = time.monotonic(), set()
            while process.poll() is None:
                if time.monotonic() - start > 420:
                    raise TimeoutError("Bounded live-size run exceeded 420 seconds")
                text = log.read_text(errors="replace")
                for step, desired in re.findall(r"RHINE_LIVE_SIZE\|([a-z-]+)\|([a-z-]+)", text):
                    if step in seen:
                        continue
                    require(step in requests and desired == requests[step][1], "Unexpected size request")
                    before = pid()
                    previous = command(["xcrun", "simctl", "ui", args.device, "content_size"])
                    command(["xcrun", "simctl", "ui", args.device, "content_size", desired])
                    actual = command(["xcrun", "simctl", "ui", args.device, "content_size"])
                    after = pid()
                    records["events"].append({
                        "test": requests[step][0], "step": step, "requested": desired,
                        "readbackBefore": previous, "readback": actual,
                        "pidBefore": before, "pidAfter": after,
                    })
                    save()
                    require(actual == desired, f"System size readback mismatch for {step}: {actual}")
                    require(before == after, "System preference must not restart the app")
                    seen.add(step)
                    print(f"{step}: {actual}", flush=True)
                time.sleep(0.2)
            records["testExitCode"] = process.returncode
            save()
        validate_results()
    except Exception as error:
        records["driverError"] = str(error)
        save()
        print(f"Live-size verification failed: {error}", file=sys.stderr)
    finally:
        try:
            if process is not None and process.poll() is None:
                os.killpg(process.pid, signal.SIGTERM)
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait(timeout=10)
            if process is not None:
                records["testExitCode"] = process.returncode
        except Exception as error:
            records["processCleanupError"] = str(error)
        try:
            command(["xcrun", "simctl", "ui", args.device, "content_size", original])
            records["restorationReadback"] = command(["xcrun", "simctl", "ui", args.device, "content_size"])
            records["restored"] = records["restorationReadback"] == original
            require(records["restored"], "Original system size was not restored")
        except Exception as error:
            records["restorationError"] = str(error)
        save()
    return 0 if (records["validationPassed"] and records["restored"]
                 and not any(key in records for key in ("driverError", "processCleanupError", "restorationError"))) else 1


if __name__ == "__main__":
    raise SystemExit(main())
