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

    stringProperties = objectProperties.dup;
    stringProperties["length"] = new RFunction("length", function OBSObject(OBSObject[] parameters) {
        const len = (cast(RString) parameters[0]).toString().walkLength;
        return new RNumber(len);
    });
    stringProperties["replace"] = new RFunction("replace", function OBSObject(OBSObject[] parameters) {
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
        (cast(RArray) parameters[0]).push(parameters[1]);
        return parameters[0];
    });
    arrayProperties["pop"] = new RFunction("pop", function OBSObject(OBSObject[] parameters) {
        return (cast(RArray) parameters[0]).pop();
    });

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

    long toNumber() const
    {
        throw new Exception("Geçerli bir sayı değil.");
    }

    OBSObject getProperty(string name)
    {
        if (auto p = name in properties)
        {
            return (*cast(RFunction*) p).dup().setBind(this);
        }
        throw new Exception("%s niteliği bulunmuyor.".format(name));
    }

    override bool opEquals(Object object) const
    {
        return typeid(this) == typeid(object);
    }

    override int opCmp(Object object) const
    {
        if (this.toNumber() == (cast(OBSObject) object).toNumber())
        {
            return 0;
        }
        else if (this.toNumber() < (cast(OBSObject) object).toNumber())
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

    @property string toString() const
    {
        return to!string(value);
    }
}

class RNumber : OBSObject
{
    long value;
    this(long value)
    {
        this.value = value;
        this.properties = objectProperties;
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

    long toNumber() const
    {
        return value;
    }

    bool opEquals(Object object) const
    {
        return typeid(this) == typeid(object) && (cast(RNumber) object).toNumber() == this.toNumber();
    }

    @property string toString() const
    {
        return to!string(value);
    }

    OBSObject opAdd(OBSObject t)
    {
        return new RNumber(this.value + (cast(RNumber) t).value);
    }

    OBSObject opMul(OBSObject t)
    {
        return new RNumber(this.value * (cast(RNumber) t).value);
    }

    OBSObject opDiv(OBSObject t)
    {
        return new RNumber(this.value / (cast(RNumber) t).value);
    }

    OBSObject opSub(OBSObject t)
    {
        return new RNumber(this.value - (cast(RNumber) t).value);
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

    @property string toString() const
    {
        return to!string(value);
    }

    OBSObject opAdd(OBSObject t)
    {
        return new RString(this.value ~ (cast(RString) t).value);
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
        auto ret = array.back();
        array.popBack();
        return ret;
    }

    @property size_t length(){
        return array.length;
    }


override:

    OBSObject opIndex(OBSObject i) {
        return array[i.toNumber()];
    }

    void opIndexAssign(ref OBSObject value, ref OBSObject key){
        array[key.toNumber()] = value;
    }

    @property int opDollar(size_t dim : 0)() { return array.length; }

    OBSObject getType() const
    {
        return new RString("Array");
    }

    bool toBool() const
    {
        return array.length > 0;
    }

    @property string toString() const
    {
        return to!string(array);
    }
}
