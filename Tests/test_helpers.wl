(* Test helpers — shared across all test files *)
(* Loaded by run_tests.wl before running individual test files *)

print[a___] := WriteString["stdout", a, "\n"];

$results = <||>;

SetAttributes[test, HoldRest];
test[id_String, input_, expected_] := With[{obj = VerificationTest[input, expected, TestID -> id]},
    $results[id] = obj;
    If[obj["Outcome"] === "Success",
        print["  \[Checkmark] ", id],
        print["  \[Times] ", id];
        print["    Expected: ", Short[obj["ExpectedOutput"] // ReleaseHold, 2]];
        print["    Got:      ", Short[obj["ActualOutput"] // ReleaseHold, 2]];
    ];
];

SetAttributes[testQ, HoldRest];
testQ[id_String, input_] := test[id, input, True];
