#!/usr/bin/env wolframscript

(* CA Paclet Test Runner *)
(* Run with: wolframscript -f Tests/run_tests.wl *)

print[a___] := WriteString["stdout", a, "\n"];

print["=== CA Paclet Test Suite ==="];
print[""];

(* Load paclet *)
print["Loading paclet..."];
PacletDirectoryLoad[FileNameJoin[{DirectoryName[$InputFileName, 2], "CellularAutomaton"}]];
Needs["WolframInstitute`CellularAutomaton`"];
print["Paclet loaded."];
print[""];

(* Load test helpers *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "test_helpers.wl"}]];

(* Run test files *)
testFiles = {
    "core_tests.wl",
    "cross_validation_tests.wl",
    "nks_doubler_tests.wl"
};

Do[
    print["========== ", file, " =========="];
    print[""];
    Get[FileNameJoin[{DirectoryName[$InputFileName], file}]];
    print[""];,
    {file, testFiles}
];

(* Summary *)
$total = Length[$results];
$passed = Count[$results, _?(#["Outcome"] === "Success" &)];
$failed = $total - $passed;
$failNames = Keys[Select[$results, #["Outcome"] =!= "Success" &]];

print["=== Results ==="];
print["Total:  ", $total];
print["Passed: ", $passed];
print["Failed: ", $failed];

If[$failed > 0,
    print[""];
    print["Failed tests:"];
    Scan[print["  - ", #] &, $failNames];
    print[""];
    print["SOME TESTS FAILED"];
    Exit[1];
    ,
    print[""];
    print["ALL TESTS PASSED"];
    Exit[0];
];
