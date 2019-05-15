module builtin;
import std.stdio;
import obsobject;
import std.conv;
import std.random;
import core.memory;
import std.algorithm : map;

OBSObject _print(OBSObject[] parameters)
{
    foreach (param; parameters)
    {
        write(param);
    }
    writeln();
    return _true;
}

OBSObject _uniform(OBSObject[] parameters)
{
    try
    {
        return new RNumber(uniform(parameters[0].toNumber(), parameters[1].toNumber()));
    }
    catch (Exception err)
    {
        return _false;
    }
}

OBSObject _rnd_dice(OBSObject[] parameters)
{
    try
    {
        return new RNumber(cast(long) dice(parameters.map!(param => param.toNumber())));
    }
    catch (Exception err)
    {
        return _false;
    }
}
