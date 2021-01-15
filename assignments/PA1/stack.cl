(*
 *  CS164 Fall 94
 *
 *  Programming Assignment 1
 *    Implementation of a simple stack machine.
 *
 *  Skeleton file
 *)

class StackCommand {
    prevCmd : StackCommand;
    pushTo(cmd: StackCommand) : StackCommand { {
        prevCmd <- cmd;
        self;
    }};
    pop(): StackCommand {
        prevCmd
    };
    display() : String {""};
    execute() : StackCommand {self};
    get() : Int {0};
};

class IntCommand inherits StackCommand {
    data : Int;
    init(n : Int) : IntCommand {{
        data <- n;
        self;
    }};
    display() : String {
        (new A2I).i2c(data).concat("\n").concat(if(isvoid(prevCmd)) then "" else prevCmd.display() fi)
    };
    execute() : StackCommand {
        self
    };
    get() : Int {data};
};

class SwapCommand inherits StackCommand {
    execute() : StackCommand {
        let prevStack : StackCommand <- pop(),
            prev2Stack : StackCommand <- prevStack.pop(),
            prev3Stack : StackCommand <- prev2Stack.pop() in {
            prevStack <- prevStack.pushTo(prev3Stack);
            prevStack <- prev2Stack.pushTo(prevStack);
            prevStack;
        }
    };
    display() : String {"s\n".concat(if(isvoid(prevCmd)) then "" else prevCmd.display() fi)};
};

class AddCommand inherits StackCommand {
    execute() : StackCommand {
        let lhs : StackCommand <- pop(),
            rhs : StackCommand <- lhs.pop(),
            sum : Int <- lhs.get() + rhs.get() in (new IntCommand.init(sum).pushTo(rhs.pop()))
    };
    display() : String {"+\n".concat(if(isvoid(prevCmd)) then "" else prevCmd.display() fi)};
};

class Main inherits IO {

    done : Bool <- false;
    stack : StackCommand <- (new StackCommand);
    cmdStr : String;

    main() : Object {
        while not done loop {
            cmdStr <- in_string();
            out_string(">".concat(cmdStr).concat("\n"));
            stack <- if cmdStr = "x" then
                {done <- true; stack;}
            else if cmdStr = "+" then
                (new AddCommand).pushTo(stack)
            else if cmdStr = "s" then
                (new SwapCommand).pushTo(stack)
            else if cmdStr = "e" then 
                stack.execute()
            else if cmdStr = "d" then
                {out_string(stack.display()); stack;}
            else 
                (new IntCommand).init((new A2I).c2i(cmdStr)).pushTo(stack)
            fi fi fi fi fi;
        } pool
    };

};
