# HexCompiler

This is a lua compiler for the Minecraft mod called Hexcasting. 
It is designed to be used in game via the mod Computer Craft.


## Language Details

### Numbers
Numbers are represented naturally (no distinctions between integers and floats). *examples:*
`1`, `123`, `1.23`, `1.0`, `-4.5`

### Booleans
Either `true` or `false`

### Null
Represented by `null`

### Vectors
List of three comma seperated coordinate values (x, y, z) surrounded by curly braces. *examples:* `{0,0,0}`, `{1, 2, 3}`, `{0, -1, 0}`, `{true, 0, 1}` (although using non-number values will cause an error at runtime)

### Lists
Set of comma seperated values surrounded by square brackets. *examples:* `[1, 2, 3]`, `[true]`, `[]`, `[1, [2, 3], 4]`

### Function values
Functions can be created using the `function` keyword, and are treated as values. They are inherently anonymous, and do not store any information about themselves. For example, this means there will not be an error if you try to call a function with the wrong number of arguments (but things will go wrong nonetheless).
*examples:* `function() {...}`, `function(a) {...}`, `function(a, b, c) {...}` (more details on `...` below)

### Inline Hex
This is a way of bypassing the compiler and directly writing patterns to the output. Double quotes are used to indicate this, with values inserted using curly braces. The resulting effect ***must*** be that a single value has been added to the stack. *examples:* `"consideration one"`, `"minds_reflection"`, `{a} reveal`
#### **CURRENT ISSUE:**
There is no way to indicate to the compiler if the stack has been altered part way through the inline notation. Because of this, variable access will become misaligned. To avoid, only access variables when the stack is the same size as it was at the start of the inline hex value.

### Operators
Special cases (like vector division being the cross product) can be found in the Hexcasting mod book.
| Name                  | Syntax(s)     |
|-----------------------|---------------|
|Addition               |a + b          |
|Subtraction            |a - b          |
|Multiplication         |a * b          |
|Division (not floor)   |a / b          |
|Exponentiate           |a ** b         |
|Modulo                 |a % b          |
|Equal                  |a == b         |
|Not Equal              |a != b         |
|Greater Than           |a > b          |
|Greater Than or Equal  |a >= b         |
|Less Than              |a < b          |
|Less Than or Equal     |a <= b         |
|And                    |a and b, a & b |
|Or                     |a or b, a \| b |
|Xor                    |a xor b, a ^ b |

### Other values
Although there is only syntax present for the above, any other values that can be created (like entities) are valid and have interactions.

## Comments
There are two types of comments available, line and block. Syntax is as follows:
```
// line comment

/* Block
Block
Comment
*/

```

### Variables
Variables are block scoped and defined with the `let` keyword, they can also be given initial values by using an assignment statement.
*example:*
```
let my_variable;
let other_var = 5;
```
Variables can be assigned to using the assignment operator (`=`), optionally preceded by a normal operator if the left hand side of an operator is the variable itself.
*example:*
```
let my_variable;
my_variable = 1 + 2;
my_variable = my_variable + 6;
my_variable += 6; // same as previous line.
```
There exists a shorthand for incrementing and decrementing a variable by 1, in the following form:
```
let counter = 0;

counter++; // increases counter by 1
counter += 1; // same thing
counter = counter + 1; // same thing again

counter--; // decreases counter by 1
counter -= 1; // same thing
counter = counter - 1; // same thing again
```
List variables have special syntax for changing the value at a particular index (which start at 1). This can be nested as much as desired.
```
let my_list = [1, 2, 3, 5, 6];

my_list[3] = [4, 5]; // [1, 2, [3, 5], 5, 6]
my_list[3][2] = 4; // [1, 2, [3, 4], 5, 6]

```
They can also be deleted from the scope early using the `delete` keyword. This frees up stack space and is generally a good idea to do early if possible.
*example:*
```
let other_var = 5;
// do stuff
delete other_var;
// stack now more free
```

### If statements
These allow conditions to change how the program executes. They can be chained using else statements like so:
```
let a = 4;

let b;
if (a == 3) {
    b = 1;
} else if (a > 3) {
    b = 2;
} else {
    b = 0;
}
print(b); // 2
```

### Functions
Functions are values that contain code within them. They can be created and immediately used, or stored into a variable. They can\* be recursive (call themselves) and have multiple return points (specified with the `return` keyword). *examples:*
```
let my_function = function(a, b) {
    return a + b;
}
print(my_function(1, 2)); // 3
let other_function = function(a, b) {
    if (a > b) {
        return a - b;
    } else if (b > a) {
        return b - a;
    }
    return 1;
}
print(other_function(3, 5)); // 2
```
\* There is a minor technicality with recursion currently, as a variable has to be declared already to be used within the function. This means that directly declaring a variable as a function and attempting to use recursion will fail. Instead, declare it before assigning the value. *example:*
```
let factorial;
factorial = function(n) {
    if (n == 0) {
        return 1;
    }
    return n * factorial(n - 1)
};
print(factorial(3)); // 6
```

### For Loops
Loops can be used to repeat code, often iterating over elements. While loops are not implemented currently (since the underlying system makes them difficult, although they can be achieved through recursion if needed). There are two main types of for loops:
#### For-in loops
These iterate over a given list and have a variable take on the value at each index from 1 to the size of the list.
```
for (value in list) {
    print(value); // prints each value in list
}

for (v in [1, 6, 2, 8, 4]) {
    print(v); // prints 1, 6, 2, 8, 4
}
```
#### For-range loops
These use an arrow (`->`) notation to specify a range for a value to take on.
```
for (i = min -> max) {
    print(i); // prints all values between min-max (inclusive)
}

for (i = 1 -> 5) {
    print(i); // prints 1, 2, 3, 4, 5
}
```
There is also some special syntax for changing the step size
```
for (i = 1 -> 10 by 2) {
    print(i); // prints 1, 3, 5, 7, 9 (stops since 11 > 10)
}
for (i = 5 -> 1 by -1) {
    print(i); // prints 5, 4, 3, 2, 1
}
```
And shorthand for starting at 1
```
for (i -> 5) {
    print(i); // prints 1, 2, 3, 4, 5
}
```

### Properties
Properties represent specific values that can be accessed on values. These require a dot (`.`) followed by a name. Some properties are actually methods, which act like functions and require arguments. However, since these are not truly functions, they cannot be used as values, and they will fail to compile if given the wrong number of arguments.
#### Property List
|Type   |Name       |Description                |
|-------|-----------|---------------------------|
|Vector |x          |x component                |
|Vector |y          |y component                |
|Vector |z          |z component                |
|Vector |axis       |closest integer unit vector|
|Entity |eyes       |vector at eyes             |
|Entity |feet       |vector at feet             |
|Entity |looking    |vector in looking dir      |
|Entity |height     |height                     |
|Entity |velocity   |vector of velocity         |
|List   |length     |number of elements         |

#### Method List
|Type   |Name               |Params         |Description                        |
|-------|-------------------|---------------|-----------------------------------|
|Vector |raycast            |direction      |vector at hit block                |
|Vector |raycast_side       |direction      |unit vec of hit block side         |
|Vector |raycast_entity     |direction      |entity hit by ray                  |
|Vector |get_entity         |               |entity at this position            |
|Vector |get_animal         |               |animal at this position            |
|Vector |get_monster        |               |monster at this position           |
|Vector |get_item           |               |item at this position              |
|Vector |get_player         |               |player at this position            |
|Vector |get_living         |               |living entity at this position     |
|Vector |nearby_animal      |radius         |every animal within radius         |
|Vector |nearby_non_animal  |radius         |every non animal within radius     |
|Vector |nearby_monster     |radius         |every monster within radius        |
|Vector |nearby_non_monster |radius         |every non monster within radius    |
|Vector |nearby_item        |radius         |every item within radius           |
|Vector |nearby_non_item    |radius         |every non item within radius       |
|Vector |nearby_player      |radius         |every player within radius         |
|Vector |nearby_non_player  |radius         |every non player within radius     |
|Vector |nearby_living      |radius         |every living within radius         |
|Vector |nearby_non_living  |radius         |every non living within radius     |
|Vector |nearby_anys        |radius         |every entity within radius         |
|Vector |library_read       |pattern        |value read from the library at pos |
|Vector |library_write      |pattern, value |void, writes to the library at pos |
|List   |slice              |start, stop    |inclusive sublist start...stop     |
|List   |add_end            |value          |list with value added to end       |
|List   |add_start          |value          |list with value added to start     |
|List   |remove_end         |               |list with value at end removed     |
|List   |remove_start       |               |list with value at start removed   |
|List   |concat             |with           |combined list with all elements    |
|List   |reversed           |               |list with order reversed           |
|List   |unique             |               |list containing no duplicates      |
|List   |find               |value          |index of value in the list         |
|List   |remove             |index          |list with value at index removed   |
|Entity |read               |               |value read from the entity         |
|Entity |write              |value          |void, writes value to the entity   |
|Entity |readable           |               |true if can be read from           |
|Entity |writeable          |               |true if can be written to          |
|Entity |impulse            |vector         |applies an impulse to entity       |
|Entity |blink              |distance       |teleports and entity forward       |
|Entity |weakness           |time, amplitude|applies weakness effect            |
|Entity |levitation         |time           |applies levitation effect          |
|Entity |wither             |time, amplitude|applies wither effect              |
|Entity |poison             |time, amplitude|applies poison effect              |
|Entity |slowness           |time, amplitude|applies slowness effect            |
|Entity |regeneration       |time, amplitude|applies regeneration effect        |
|Entity |night_vision       |time           |applies night vision effect        |
|Entity |absorption         |time, amplitude|applies absorption effect          |
|Entity |haste              |time, amplitude|applies haste effect               |
|Entity |strength           |time, amplitude|applies strength effect            |
|Entity |craft_cypher       |pattern        |uses this battery for a cypher     |
|Entity |craft_trinket      |pattern        |uses this battery for a trinket    |
|Entity |craft_artifact     |pattern        |uses this battery for an artifact  |
|Entity |craft_phial        |               |uses this battery for a phial      |
|Entity |recharge_item      |               |uses this battery to recharge      |
|Entity |flight_range       |range          |allows flight in this range        |
|Entity |flight_time        |time           |allows flight for this time        |
|Entity |flight_elytra      |               |gives a temporary elytra           |
|Entity |teleport           |vector         |offsets the position by the vector |
|Entity |flay_mind          |vector         |flays a mind...                    |



### Global Values
# unfinished
###