ref = [0]
def rid():
    ref[0] += 1
    return f"RBX{ref[0]:04d}"
def color(r, g, b):
    return (0xFF << 24) | (r << 16) | (g << 8) | b
MAT = {"smooth": 272, "neon": 288}
def part(name, pos, size, rgb, mat="smooth", cls="Part"):
    x, y, z = pos; sx, sy, sz = size
    return f'''<Item class="{cls}" referent="{rid()}"><Properties>
<bool name="Anchored">true</bool>
<CoordinateFrame name="CFrame"><X>{x}</X><Y>{y}</Y><Z>{z}</Z><R00>1</R00><R01>0</R01><R02>0</R02><R10>0</R10><R11>1</R11><R12>0</R12><R20>0</R20><R21>0</R21><R22>1</R22></CoordinateFrame>
<Color3uint8 name="Color3uint8">{color(*rgb)}</Color3uint8>
<token name="Material">{MAT[mat]}</token>
<string name="Name">{name}</string>
<Vector3 name="size"><X>{sx}</X><Y>{sy}</Y><Z>{sz}</Z></Vector3>
</Properties></Item>'''
def folder(name, children):
    return f'<Item class="Folder" referent="{rid()}"><Properties><string name="Name">{name}</string></Properties>{"".join(children)}</Item>'
def script(cls, name, path):
    src = open(path, encoding="utf-8").read()
    return f'<Item class="{cls}" referent="{rid()}"><Properties><string name="Name">{name}</string><ProtectedString name="Source"><![CDATA[{src}]]></ProtectedString></Properties></Item>'

GREEN=(60,200,90); GOLD=(255,200,40); STONE=(90,90,100); DARK=(55,55,65)
RED=(255,40,40); LAVA=(255,90,0); BLUE=(60,150,255)
S = 40
seg = lambda i: (i-1)*S
cps, plats, kills, movers = [], [], [], []
for i in range(1, 11):
    cps.append(part(str(i), (0,0,seg(i)), (10,1,10), GOLD if i==10 else GREEN, "neon" if i==10 else "smooth"))
z=seg(1)
for k,dz in enumerate([10,17,24,31]): plats.append(part(f"S1_{k}",(0,0,z+dz),(4,1,4),STONE))
z=seg(2)
for k,dz in enumerate([10,17,24,31]): plats.append(part(f"S2_{k}",(4 if k%2==0 else -4,0,z+dz),(4,1,4),STONE))
z=seg(3); plats.append(part("S3_beam",(0,0,z+20),(1.5,1,30),DARK))
z=seg(4)
for k,(dz,y) in enumerate([(10,2),(17,4),(24,3),(31,1)]): plats.append(part(f"S4_{k}",(0,y,z+dz),(4,1,4),STONE))
z=seg(5); plats.append(part("S5_path",(0,0,z+20),(6,1,30),DARK))
for k,dz in enumerate([12,20,28]): kills.append(part(f"S5_kill{k}",(0,1.25,z+dz),(6,1.5,1),RED,"neon"))
z=seg(6)
for k,dz in enumerate([10,20,30]): movers.append(part(f"S6_lift{k}",(0,0,z+dz),(5,1,5),BLUE,"neon"))
z=seg(7)
for k,dz in enumerate([9,15,21,27,33]): plats.append(part(f"S7_{k}",(0,0,z+dz),(2,1,2),STONE))
z=seg(8); plats.append(part("S8_path",(0,0,z+20),(8,1,30),DARK))
kills += [part("S8_killL",(-2,0.6,z+12),(4,0.2,5),RED,"neon"),
          part("S8_killR",(2,0.6,z+22),(4,0.2,5),RED,"neon"),
          part("S8_killL2",(-2,0.6,z+30),(4,0.2,4),RED,"neon")]
z=seg(9)
for k,dz in enumerate([10,16.5,23,29.5]): plats.append(part(f"S9_{k}",(0,0,z+dz),(1.5,1,1.5),STONE))
kills.append(part("LavaFloor",(0,-8,180),(80,1,440),LAVA,"neon"))
spawn = part("Spawn",(0,0,-14),(10,1,10),GREEN,"smooth",cls="SpawnLocation")

xml = f'''<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
<Item class="Workspace" referent="{rid()}"><Properties><string name="Name">Workspace</string></Properties>
{spawn}
{folder("Checkpoints", cps)}
{folder("Platforms", plats)}
{folder("KillBricks", kills)}
{folder("MovingPlatforms", movers)}
</Item>
<Item class="ServerScriptService" referent="{rid()}"><Properties><string name="Name">ServerScriptService</string></Properties>
{script("Script","GameServer","../src/ServerScriptService/GameServer.server.lua")}
</Item>
<Item class="StarterPlayer" referent="{rid()}"><Properties><string name="Name">StarterPlayer</string></Properties>
<Item class="StarterPlayerScripts" referent="{rid()}"><Properties><string name="Name">StarterPlayerScripts</string></Properties>
{script("LocalScript","ShopGui","../src/StarterPlayerScripts/ShopGui.client.lua")}
</Item></Item>
</roblox>'''
open("../place/LavaObby.rbxlx","w",encoding="utf-8").write(xml)
print("parts:", len(cps)+len(plats)+len(kills)+len(movers)+1)
