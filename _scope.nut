// We are giving this function to all CBaseEntity entities
local ROOT=getroottable()
// Our function in question doesn't allow "printl" because it is not in the scope of the entity
::CBaseEntity_MapBaseTest <- function()
{
    printl("Hello World")
}

// This adds the function "MapBaseTest" to all entities that pass these parameters
local entity_classes = [];

foreach ( key, value in ROOT )
{
    if ( typeof(value) == "class" && "AddEFlags" in value )
        entity_classes.append(value);
}

foreach ( key, value in ROOT )
{
    if ( typeof(value) != "function" ) continue

    if ( startswith(key, "CBaseEntity_") )
    {
        local func_name = key.slice(12);
        foreach (entity_class in entity_classes) {
            entity_class[func_name] <- value.bindenv(ROOT)
        }
        delete ROOT[key]
    }
}