class TestCase {
    caseTest(fa: Int, fb: Int, fc: Int): Int {{
        case fa + fb + fc of 
            fa: Int => 43;
            fb: Int => 43;
        esac;
        case fa + fb + fc of 
            fa: Int => 43;
        esac;
    }};
    ifTest(): Object {{
        if 1 < 2 then
            7
        else
            if 3 < 4 then
                5
            else
                6
        fi + 2 fi;
    }};
};

(*
class A {
    caseTest: CaseKwTest <- new CaseKwTest;
    emptyClassTest: EmptyClassTest <- new EmptyClassTest;
    ana(): Int {{
        (let x:Int <- 1,
            y: Int <- 2,
            z: Int <- 5,
            xx: Int in {
                x <- xx + y * z + x;
                print();
                caseTest.someMethod(x, y, 0);
            }) + 3;
    }};
    print(): String {
        "aaa"
    };
};
*)

class EmptyClassTest inherits CaseKwTest {};