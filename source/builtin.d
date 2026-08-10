module builtin;
import std.stdio;
import obsobject;
import std.conv;
import std.random;
import core.memory;
import std.string : format;
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

/*
 * Built-ins validate their arguments and raise a controlled Obsidian error.
 * Returning false on failure used to make a bad call indistinguishable from a
 * legitimate false result.
*/
OBSObject _uniform(OBSObject[] parameters)
{
    if (parameters.length != 2)
        throw new Exception("uniform 2 parametre bekliyor, %s verildi.".format(parameters.length));
    const lower = parameters[0].toNumber();
    const upper = parameters[1].toNumber();
    if (!(lower < upper))
        throw new Exception("uniform için alt sınır üst sınırdan küçük olmalı: %s, %s".format(lower,
                upper));
    /* Whole numbers keep the integral behaviour the sample programs rely on. */
    return new RNumber(uniform(cast(long) lower, cast(long) upper));
}

OBSObject _rnd_dice(OBSObject[] parameters)
{
    if (parameters.length == 0)
        throw new Exception("dice en az bir ağırlık bekliyor.");
    double total = 0;
    foreach (param; parameters)
    {
        const weight = param.toNumber();
        if (weight < 0)
            throw new Exception("dice ağırlıkları negatif olamaz: %s".format(weight));
        total += weight;
    }
    if (total == 0)
        throw new Exception("dice ağırlıklarının toplamı sıfır olamaz.");
    return new RNumber(cast(long) dice(parameters.map!(param => param.toNumber())));
}
