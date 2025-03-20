import "helper/randstr"
import "math"
import "json"

map := {}

count := 0
for a in range(0, 16) {
	n := "$"+randstr(12)+".e"
	map[n] =    {
                    "type": "file",
                    "name": n,
                    "content": string(math.sin(count)*10e16+math.pi*math.sqrt(2)) + " " + randstr(18)
                }
				
				count++
}


println(string(json.indent(json.encode(map), "", "\t")))