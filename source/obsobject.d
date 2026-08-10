module obsobject;
import std.string;
import std.conv;
import std.stdio;
import std.range.primitives;
static RBoolean _true, _false;

static OBSObject[string] objectProperties, stringProperties, numberProperties,
    arrayProperties;

static this()
{
    _true = new RBoolean(true);
    _false = new RBoolean(false);
    objectProperties = [
        "type" : new RFunction("type", function OBSObject(OBSObject[] parameters) {
            return parameters[0].getType();
        }),
        "toString" : new RFunction("toString", function OBSObject(OBSObject[] parameters) {
            return new RString(parameters[0].toString());
        }),
    ];

    numberProperties = objectProperties.dup;

    stringProperties = objectProperties.dup;
    stringProperties["length"] = new RFunction("length", function OBSObject(OBSObject[] parameters) {
        const len = (cast(RString) parameters[0]).toString().walkLength;
        return new RNumber(len);
    });
    stringProperties["replace"] = new RFunction("replace", function OBSObject(OBSObject[] parameters) {
        expectArgs("replace", parameters, 3);
        const str = (cast(RString) parameters[0]).toString().replace(parameters[1].toString(), parameters[2].toString());
        return new RString(str);
    });
    stringProperties["toUpper"] = new RFunction("toUpper", function OBSObject(OBSObject[] parameters) {
        const str = (cast(RString) parameters[0]).toString().toUpper();
        return new RString(str);
    });
    stringProperties["toLower"] = new RFunction("toLower", function OBSObject(OBSObject[] parameters) {
        const str = (cast(RString) parameters[0]).toString().toLower();
        return new RString(str);
    });

    arrayProperties = objectProperties.dup;
    arrayProperties["length"] = new RFunction("length", function OBSObject(OBSObject[] parameters) {
        const len = (cast(RArray) parameters[0]).length();
        return new RNumber(len);
    });
    arrayProperties["push"] = new RFunction("push", function OBSObject(OBSObject[] parameters) {
        expectArgs("push", parameters, 2);
        (cast(RArray) parameters[0]).push(parameters[1]);
        return parameters[0];
    });
    arrayProperties["pop"] = new RFunction("pop", function OBSObject(OBSObject[] parameters) {
        return (cast(RArray) parameters[0]).pop();
    });

}

/*
 * Every built-in method receives its receiver as parameters[0], so `count`
 * includes the bound object itself.
*/
void expectArgs(string name, OBSObject[] parameters, size_t count)
{
    if (parameters.length != count)
        throw new Exception("%s %s parametre bekliyor, %s verildi.".format(name,
                count - 1, parameters.length ? parameters.length - 1 : 0));
}

/*
 * Interface containing the functions of objects.
*/
class OBSObject
{
    OBSObject[string] properties;
    OBSObject opCall(OBSObject[] parameters)
    {
        throw new Exception("Bu türü çağıramazsınız.");
    }

    OBSObject getType() const
    {
        return new RString("Object");
    }

    // D1 dönemindeki opAdd/opSub/opMul/opDiv artık derleyicide yok;
    // modern opBinary'yi eski sanal metotlara yönlendiriyoruz.
    OBSObject opBinary(string op)(OBSObject rhs)
    {
        static if (op == "+")
            return opAdd(rhs);
        else static if (op == "-")
            return opSub(rhs);
        else static if (op == "*")
            return opMul(rhs);
        else static if (op == "/")
            return opDiv(rhs);
        else
            static assert(false, "Desteklenmeyen operatör: " ~ op);
    }

    OBSObject opAdd(OBSObject)
    {
        throw new Exception("Bu türde toplama yapamazsınız.");
    }

    OBSObject opMul(OBSObject)
    {
        throw new Exception("Bu türde çarpma yapamazsınız.");
    }

    OBSObject opDiv(OBSObject)
    {
        throw new Exception("Bu türde bölme yapamazsınız.");
    }

    OBSObject opIndex(OBSObject) { throw new Exception("Bu türde opIndex yapamazsınız."); }

    void opIndexAssign(ref OBSObject value, ref OBSObject key){
        throw new Exception("Bu türde opIndexAssign yapamazsınız.");
    }

    OBSObject opSub(OBSObject)
    {
        throw new Exception("Bu türde çıkartma yapamazsınız.");
    }

    bool toBool() const
    {
        return false;
    }

    double toNumber() const
    {
        throw new Exception("Geçerli bir sayı değil.");
    }

    OBSObject getProperty(string name)
    {
        if (auto p = name in properties)
        {
            /* A method is copied before being bound so that two receivers
               never share the same bind slot. */
            if (auto func = cast(RFunction) *p)
                return func.dup().setBind(this);
            return *p;
        }
        throw new Exception("%s niteliği bulunmuyor.".format(name));
    }

    override bool opEquals(Object object) const
    {
        return typeid(this) == typeid(object);
    }

    override int opCmp(Object object) const
    {
        auto other = cast(OBSObject) object;
        if (other is null)
            throw new Exception("Bu türler karşılaştırılamaz.");
        const lhs = this.toNumber();
        const rhs = other.toNumber();
        if (lhs == rhs)
        {
            return 0;
        }
        else if (lhs < rhs)
        {
            return -1;
        }
        else
        {
            return 1;
        }
    }

    override @property string toString() const
    {
        throw new Exception("Bu türü string yapamazsınız.");
    }
}

/*
 * Binary operations are dynamically typed, so an operand of the wrong runtime
 * type must raise a controlled Obsidian error instead of dereferencing a
 * failed cast.
*/
private T expectType(T)(OBSObject value, string op, string expected)
{
    if (auto typed = cast(T) value)
        return typed;
    throw new Exception("%s işlemi %s bekliyor, %s verildi.".format(op, expected,
            value is null ? "hiçbir değer" : value.getType().toString()));
}

class RFunction : OBSObject
{
    string name;
    OBSObject bind;
    OBSObject function(OBSObject[]) func;
    this(string name, OBSObject function(OBSObject[]) func)
    {
        this.name = name;
        this.func = func;
        this.properties = objectProperties;
    }

    RFunction dup()
    {
        return new RFunction(name, func);
    }

    RFunction setBind(OBSObject bind)
    {
        this.bind = bind;
        return this;
    }

override:
    OBSObject getType() const
    {
        return new RString("Function");
    }

    bool toBool() const
    {
        return true;
    }

    @property string toString() const
    {
        if (bind)
            return "[Fonksiyon: %s, Adres: %s, Bind: %s]".format(name, &func, bind);
        else
            return "[Fonksiyon: %s, Adres: %s]".format(name, &func);
    }

    OBSObject opCall(OBSObject[] parameters)
    {
        if (bind)
        {
            return func([bind] ~ parameters);
        }
        else
        {
            return func(parameters);
        }
    }
}

class RBoolean : OBSObject
{
    bool value;
    this(bool value)
    {
        this.value = value;
        this.properties = objectProperties;
    }

override:
    OBSObject getType() const
    {
        return new RString("Boolean");
    }

    bool toBool() const
    {
        return value;
    }

    bool opEquals(Object object) const
    {
        auto other = cast(const RBoolean) object;
        return other !is null && other.value == this.value;
    }

    @property string toString() const
    {
        return to!string(value);
    }
}

class RNumber : OBSObject
{
    double value;
    this(double value)
    {
        this.value = value;
        this.properties = numberProperties;
    }

override:
    OBSObject getType() const
    {
        return new RString("Number");
    }

    bool toBool() const
    {
        return value != 0;
    }

    double toNumber() const
    {
        return value;
    }

    bool opEquals(Object object) const
    {
        auto other = cast(const RNumber) object;
        return other !is null && other.value == this.value;
    }

    @property string toString() const
    {
        /* Whole values are printed without a fractional part so that counters
           and indexes keep reading as integers. */
        if (value == cast(long) value && value > -9.0e18 && value < 9.0e18)
            return to!string(cast(long) value);
        return to!string(value);
    }

    OBSObject opAdd(OBSObject t)
    {
        return new RNumber(this.value + expectType!RNumber(t, "Toplama", "sayı").value);
    }

    OBSObject opMul(OBSObject t)
    {
        return new RNumber(this.value * expectType!RNumber(t, "Çarpma", "sayı").value);
    }

    OBSObject opDiv(OBSObject t)
    {
        const divisor = expectType!RNumber(t, "Bölme", "sayı").value;
        if (divisor == 0)
            throw new Exception("Sıfıra bölme yapılamaz.");
        return new RNumber(this.value / divisor);
    }

    OBSObject opSub(OBSObject t)
    {
        return new RNumber(this.value - expectType!RNumber(t, "Çıkartma", "sayı").value);
    }
}

class RString : OBSObject
{
    string value;
    this(string value)
    {
        this.value = value;
        this.properties = stringProperties;
    }

override:
    OBSObject getType() const
    {
        return new RString("String");
    }

    bool toBool() const
    {
        return value.length > 0;
    }

    bool opEquals(Object object) const
    {
        auto other = cast(const RString) object;
        return other !is null && other.value == this.value;
    }

    int opCmp(Object object) const
    {
        auto other = cast(const RString) object;
        if (other is null)
            throw new Exception("Metin yalnızca metinle karşılaştırılabilir.");
        return this.value < other.value ? -1 : (this.value > other.value ? 1 : 0);
    }

    @property string toString() const
    {
        return to!string(value);
    }

    OBSObject opAdd(OBSObject t)
    {
        return new RString(this.value ~ expectType!RString(t, "Toplama", "metin").value);
    }
}

class RArray : OBSObject
{
    OBSObject[] array;
    this(OBSObject[] array = [])
    {
        this.array = array;
        this.properties = arrayProperties;
    }

    void push(OBSObject obj){
        array ~= obj;
    }

    OBSObject pop(){
        if (array.length == 0)
            throw new Exception("Boş diziden eleman çıkarılamaz.");
        auto ret = array.back();
        array.popBack();
        return ret;
    }

    @property size_t length(){
        return array.length;
    }

    /* Index validation lives here so that opIndex and opIndexAssign report the
       same controlled error instead of tripping a D bounds check. */
    private size_t toIndex(OBSObject i)
    {
        const raw = i.toNumber();
        if (raw != cast(long) raw)
            throw new Exception("Dizi indeksi tam sayı olmalı: %s".format(raw));
        if (raw < 0 || raw >= array.length)
            throw new Exception("Dizi indeksi sınır dışı: %s (uzunluk %s)".format(
                    cast(long) raw, array.length));
        return cast(size_t) raw;
    }

override:

    OBSObject opIndex(OBSObject i) {
        return array[toIndex(i)];
    }

    void opIndexAssign(ref OBSObject value, ref OBSObject key){
        array[toIndex(key)] = value;
    }

    @property int opDollar(size_t dim : 0)() { return cast(int) array.length; }

    OBSObject getType() const
    {
        return new RString("Array");
    }

    bool toBool() const
    {
        return array.length > 0;
    }

    bool opEquals(Object object) const
    {
        auto other = cast(const RArray) object;
        if (other is null || other.array.length != this.array.length)
            return false;
        foreach (index, element; this.array)
        {
            if (element != other.array[index])
                return false;
        }
        return true;
    }

    @property string toString() const
    {
        return to!string(array);
    }
}
