t<-{
targetname="wall",
solid="6"
model="models/props/cs_office/vending_machine.mdl"
origin="-30 0 110"


}
ent<-Entities.CreateByClassname("func_wall")
ent.SetName("wall")
ent.SetSize(Vector(-116,-116,0),Vector(116,116,16))
//ent.SetModel("models/props/cs_office/vending_machine.mdl")
ent.SetSize(Vector(-116,-116,0),Vector(116,116,16))
ent.SetSolid(7)
//DispatchSpawn(ent)
ent.SetSolid(7)
ent.SetSize(Vector(-116,-116,0),Vector(116,116,16))
ent.SetOrigin(Vector(-30,0,30))
ent.SetCollisionGroup(4)
ent.Activate()
ent.SetSize(Vector(-116,-116,0),Vector(116,116,16))
ent.SetSolid(7)