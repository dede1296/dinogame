extends RefCounted
## The doors that open (world/view3d/doors.gd, story/doorway.gd): the Cabinet's door closed and
## open, from the front and aside; Chloé going into the Cabinet and coming out, her little dino
## following her, then a tall one waiting outside; the Herboristerie (Pervenche goes in first)
## at noon, the Comptoir in the evening with the tall dino; the same at low quality (pictures);
## Ferréol at night out of the warehouse and back in; Roc slipping out of the Cabinet; Chloé
## standing in the Cabinet's doorway, not faded (the jambs hide her).
## Bursts of shots (e/s/g/h/k/l/m/n) to pick the moments from. « doors » prints where everyone is.

const STEPS := [
	[0.7, "flags", ["prologue_done", "havre_arrive", "sceau_plaines", "met_roc", "ferreol_rencontre"]],
	[0.75, "talk", true], [0.8, "calm", 900.0], [0.85, "clock", 12.5], [0.9, "weather", &"clear"], [0.95, "quality", 2],
	[1.0, "zone", &"port_ambre"], [2.4, "weather", &"clear"], [2.45, "calm", 900.0], [2.5, "camera_distance", 11.0],
	[2.6, "doors", null],
	# The Cabinet's door, closed and open, from the front and aside.
	[2.7, "tp", Vector2(31.5, 10.6)], [4.0, "shot", "p01_cabinet_face_fermee"],
	[4.1, "door", ["Cabinet", true]], [4.8, "shot", "p02_cabinet_face_ouverte"], [4.85, "doors", null],
	[4.9, "tp", Vector2(34.3, 10.4)], [6.2, "shot", "p03_cabinet_34_ouverte"],
	[6.3, "door", ["Cabinet", false]], [7.0, "shot", "p04_cabinet_34_fermee"],
	# Chloé goes in, her little dino after her.
	[7.1, "tp", Vector2(31.5, 10.0)], [8.3, "hold", "move_up"], [8.6, "hold", ""],
	[8.7, "shot", "e01"], [9.0, "shot", "e02"], [9.3, "shot", "e03"], [9.6, "shot", "e04"], [9.9, "shot", "e05"],
	[10.2, "shot", "e06"], [10.5, "shot", "e07"], [10.8, "shot", "e08"], [11.1, "shot", "e09"], [11.35, "doors", null],
	[11.4, "shot", "e10"], [11.7, "shot", "e11"], [12.0, "shot", "e12"],
	[14.0, "state", null], [14.05, "doors", null], [14.1, "shot", "e13_interieur"],
	# She comes out (spawn DepuisCabinet), the door closes behind them.
	[14.3, "tp", Vector2(8.0, 9.8)], [15.3, "hold", "move_down"], [15.6, "hold", ""],
	[15.9, "shot", "s01"], [16.2, "shot", "s02"], [16.5, "shot", "s03"], [16.8, "shot", "s04"], [17.1, "shot", "s05"],
	[17.4, "shot", "s06"], [17.7, "shot", "s07"], [18.0, "shot", "s08"], [18.3, "shot", "s09"], [18.6, "shot", "s10"],
	[18.7, "doors", null], [19.0, "state", null],
	# A tall dino: it waits beside the door, outside, and joins her when she comes out.
	[19.2, "give_named", ["parasaurolophus", "Trompette", 22]], [19.3, "lead", 1], [19.4, "doors", null],
	[19.5, "tp", Vector2(31.5, 10.0)], [20.8, "hold", "move_up"], [21.1, "hold", ""],
	[21.2, "shot", "g01"], [21.5, "shot", "g02"], [21.8, "shot", "g03"], [22.1, "shot", "g04"], [22.4, "shot", "g05"],
	[22.7, "shot", "g06"], [23.0, "shot", "g07"], [23.3, "shot", "g08"], [23.6, "doors", null], [23.65, "shot", "g09"],
	[25.0, "doors", null], [25.1, "shot", "g10_interieur_sans_dino"],
	[25.3, "tp", Vector2(8.0, 9.8)], [26.3, "hold", "move_down"], [26.6, "hold", ""],
	[26.9, "shot", "h01"], [27.2, "shot", "h02"], [27.5, "shot", "h03"], [27.8, "shot", "h04"], [28.1, "shot", "h05"],
	[28.4, "shot", "h06"], [28.7, "shot", "h07"], [29.0, "shot", "h08"], [29.3, "shot", "h09"], [29.6, "shot", "h10"],
	[29.8, "doors", null], [30.0, "lead", 1],
	# Havre-Doré: the Herboristerie's door, closed and open, from the front and aside.
	[30.2, "zone", &"havre_dore"], [31.6, "weather", &"clear"], [31.65, "calm", 900.0], [31.7, "clock", 12.5],
	[31.75, "camera_distance", 9.0], [31.8, "doors", null],
	[31.9, "tp", Vector2(7.5, 11.0)], [33.2, "shot", "q01_herbo_face_fermee"],
	[33.3, "door", ["Herboristerie", true]], [34.0, "shot", "q02_herbo_face_ouverte"],
	[34.1, "tp", Vector2(10.5, 11.0)], [35.4, "shot", "q03_herbo_34_ouverte"],
	[35.5, "door", ["Herboristerie", false]], [36.2, "shot", "q04_herbo_34_fermee"],
	# Talking to Pervenche: she goes in first, Chloé follows (her little dino too), the shop.
	[36.25, "weather", &"clear"], [36.3, "tp", Vector2(6.0, 10.6)], [37.5, "hold", "move_up"], [37.55, "hold", ""], [37.6, "pick", 0], [37.65, "interact_now", null],
	[38.0, "shot", "k01"], [38.3, "shot", "k02"], [38.6, "shot", "k03"], [38.9, "shot", "k04"], [39.2, "shot", "k05"],
	[39.5, "shot", "k06"], [39.8, "shot", "k07"], [40.1, "shot", "k08"], [40.4, "shot", "k09"], [40.7, "shot", "k10"],
	[41.0, "shot", "k11"], [41.3, "shot", "k12"], [41.6, "shot", "k13"], [41.9, "shot", "k14"], [42.2, "shot", "k15"],
	[42.5, "doors", null], [43.0, "shot", "k16_boutique"], [43.1, "press", "cancel"],
	[43.4, "shot", "l01"], [43.7, "shot", "l02"], [44.0, "shot", "l03"], [44.3, "shot", "l04"], [44.6, "shot", "l05"],
	[44.9, "shot", "l06"], [45.2, "shot", "l07"], [45.5, "shot", "l08"], [45.8, "shot", "l09"], [46.1, "shot", "l10"],
	[46.5, "doors", null], [46.6, "state", null],
	# The Comptoir in the evening, the tall dino waiting outside.
	[46.8, "clock", 19.4], [46.85, "weather", &"clear"], [46.9, "lead", 1], [46.95, "camera_distance", 11.0],
	[47.0, "tp", Vector2(34.5, 11.2)], [48.4, "shot", "r01_comptoir_soir_fermee"],
	[48.5, "tp", Vector2(33.0, 10.7)], [49.7, "hold", "move_up"], [49.75, "hold", ""], [49.8, "pick", 0], [49.85, "interact_now", null],
	[50.2, "shot", "m01"], [50.5, "shot", "m02"], [50.8, "shot", "m03"], [51.1, "shot", "m04"], [51.4, "shot", "m05"],
	[51.7, "shot", "m06"], [52.0, "shot", "m07"], [52.3, "shot", "m08"], [52.6, "shot", "m09"], [52.9, "shot", "m10"],
	[53.2, "shot", "m11"], [53.5, "shot", "m12"], [53.8, "shot", "m13"], [54.1, "shot", "m14"],
	[54.5, "doors", null], [55.0, "shot", "m15_boutique"], [55.1, "press", "cancel"],
	[55.4, "shot", "n01"], [55.7, "shot", "n02"], [56.0, "shot", "n03"], [56.3, "shot", "n04"], [56.6, "shot", "n05"],
	[56.9, "shot", "n06"], [57.2, "shot", "n07"], [57.5, "shot", "n08"], [57.8, "shot", "n09"], [58.1, "shot", "n10"],
	[58.5, "doors", null], [58.6, "state", null],
	# Low quality (pictures): no leaves, the same walks and the door's sound.
	[59.0, "clock", 12.5], [59.1, "quality", 0], [59.2, "lead", 1], [60.5, "doors", null],
	[60.6, "tp", Vector2(6.0, 10.6)], [61.8, "hold", "move_up"], [61.85, "hold", ""], [61.9, "pick", 0], [61.95, "interact_now", null],
	[63.3, "shot", "b01_basse"], [64.3, "shot", "b02_basse"], [66.8, "shot", "b03_basse_boutique"], [66.9, "press", "cancel"],
	[68.0, "shot", "b04_basse_sortie"], [70.0, "shot", "b05_basse_fin"], [70.1, "doors", null], [70.2, "state", null],
	[70.3, "quality", 2],
	# One night at Havre-Doré: Ferréol comes out of the warehouse to meet Isaure, and goes back in.
	[70.5, "dlog", true], [70.6, "tp", Vector2(44.3, 20.0)], [71.5, "clock", 21.8],
	[72.0, "shot", "x01"], [72.5, "shot", "x02"], [73.0, "shot", "x03"], [73.5, "shot", "x04"], [74.0, "shot", "x05"],
	[74.5, "shot", "x06"], [75.0, "shot", "x07"], [75.5, "shot", "x08"], [76.0, "shot", "x09"], [76.5, "shot", "x10"],
	[77.0, "shot", "x11"], [77.5, "shot", "x12"], [78.0, "shot", "x13"], [78.5, "shot", "x14"], [79.0, "shot", "x15"],
	[79.5, "shot", "x16"], [80.0, "shot", "x17"], [80.5, "shot", "x18"], [81.0, "shot", "x19"], [81.5, "shot", "x20"],
	[82.0, "shot", "x21"], [82.5, "shot", "x22"], [83.0, "shot", "x23"], [83.5, "shot", "x24"], [84.0, "shot", "x25"],
	[84.5, "shot", "x26"], [85.0, "shot", "x27"], [85.5, "shot", "x28"], [86.0, "shot", "x29"], [86.5, "shot", "x30"],
	[87.0, "shot", "x31"], [87.5, "shot", "x32"], [88.0, "shot", "x33"], [88.5, "shot", "x34"], [89.0, "shot", "x35"],
	[89.5, "shot", "x36"], [90.0, "shot", "x37"], [90.5, "shot", "x38"], [91.0, "shot", "x39"], [91.5, "shot", "x40"],
	[92.0, "state", null],
	# Back at Port-Ambre after Maïa's challenge: Roc slips out of the Cabinet (its door opens, stays open).
	[92.5, "flags", ["maia_defi_1"]], [92.6, "zone", &"port_ambre"],
	[94.0, "shot", "y01"], [94.5, "shot", "y02"], [95.0, "shot", "y03"], [95.5, "shot", "y04"], [96.0, "shot", "y05"],
	[96.5, "shot", "y06"], [97.0, "shot", "y07"], [97.5, "shot", "y08"], [98.0, "shot", "y09"], [98.5, "shot", "y10"],
	[99.0, "shot", "y11"], [99.5, "shot", "y12"], [100.0, "shot", "y13"], [100.5, "shot", "y14"], [101.0, "shot", "y15"],
	[101.5, "shot", "y16"], [102.0, "shot", "y17"], [102.5, "shot", "y18"], [103.0, "shot", "y19"], [103.5, "shot", "y20"],
	[104.0, "shot", "y21"], [104.5, "shot", "y22"], [105.0, "shot", "y23"], [105.5, "shot", "y24"], [106.0, "shot", "y25"],
	[106.5, "shot", "y26"], [107.0, "shot", "y27"], [107.5, "shot", "y28"], [108.0, "shot", "y29"], [108.5, "shot", "y30"],
	[109.0, "doors", null], [109.1, "state", null],
	# In the Cabinet's doorway, not faded: the jambs and the lintel hide her (depth), then out.
	[109.5, "clock", 12.5], [109.6, "weather", &"clear"], [109.7, "tp", Vector2(31.5, 10.4)],
	[111.0, "door_peek", ["Cabinet", 0.0]], [112.2, "shot", "z01_embrasure"],
	[112.3, "door_peek", ["Cabinet", -0.55]], [113.5, "shot", "z02_embrasure_jambage"],
	[113.6, "door_out", "Cabinet"], [116.0, "shot", "z03_sortie"], [116.1, "doors", null],
]
