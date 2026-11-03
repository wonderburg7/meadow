# Specialist ecology evidence

<!-- CONTEXT: reference | LAYER: reference -->
Status: reference | Owner: Dave / Codex | Next: retain this durable reference; reopen measurement only for a new explicit ecology design question | Dependency: retained SE-2 artefacts and existing PP-4 seed-set behaviour | Verified: 2026-11-01

## Question and scope

Dave selected the Clover-versus-Borage specialist comparison on 1 Nov 2026.
This measures specialist steering in a supported, accelerated colony.
The earlier Clover-only evidence remains in `plans/reference/seed-set-evidence.md`.

## Measurements

All twenty serial arms passed with every action resolved. Seeds 12345, 7, 2026,
90210 and 555 each ran Clover/off, Clover/on, Borage/off and Borage/on.
The reporter validated the complete treatment matrix, common provenance and
controls before aggregation. Clover arms were rerun rather than spliced from EE-2.

Reproduce from the recorded baseline with the committed fixture:

~~~powershell
python tools/seed_set_evidence.py specialists --fixture test_scenarios/se2_specialist_spring.json --output C:/Users/dl13860/Documents/Meadow/evidence/SE-2-specialist-spring
~~~

The output directory must be empty for a new run. Retained artefacts are at
`C:/Users/dl13860/Documents/Meadow/evidence/SE-2-specialist-spring/`.
`report.json` retains exact values; `report.md` renders every raw arm, paired
effect, contrast and summary; `provenance.json` pins all controls. Each
`<seed>-<specialist>-<off|on>/` retains its scenario, verdict, process log,
session JSONL and complete `private_user` saves.

Baseline: `09d07308f190f395ce42299b0e8eaf956d140ef7`; engine: `4.7.2.stable.official.ed1daf0bf`; fixed 30 fps.
Reporter SHA-256: `cdfeb8e996c5322027132cb4fc7f8b1a8118758f7f823a1e277deea3daeb938d`.
Fixture SHA-256: `01e783185aca9463c8a7cf0b5ee523baf730e49e6c7cdfe18dbbfba8954e8463`.

The new fixture is a byte-identical copy of the current EE-2 spring fixture:
12 cells, 24 nectar and 6 pollen specialists, no other workers, 600 initial
honey, 20-second days, ten-day seasons, winter enabled, a one-day countdown,
ten-day winter, 0.01 winter burn factor, three-day spring regrowth and
0.1-second replacement. Weather, disease, predators and rivals remain disabled.
Only specialist species and seed-set flag change treatments; seed varies between
matched sets. Saves are forward day 10 (180.750 s) and day 25 (480.750 s), with
no restore. Spring replacements use [400, 460) s. Every enabled arm rolled once;
disabled arms had no rollover. Saved spring banks matched logged rollover counts.

Vectors use **Clover / Borage / Foxglove / Poppy / Bramble / Dandelion**.
Shares use all live flowers, absent species is zero, and an empty meadow is
undefined. All shares here are defined. Shares are percentages; differences
are percentage points (pp). Rounding is to four decimals; exact values remain
in the retained JSON. Counts are flowers or ledger events.

### Complete arm observations

S = summer, P = spring, delta = P - S. Summer spring-count ledgers and all
disabled-arm ledgers are zero, shown explicitly below.

| Seed | Specialist/flag | Phase | Live counts | Share % / delta pp | Seed ledger | Spring ledger |
| --- | --- | --- | --- | --- | --- | --- |
| 12345 | Clover/off | S | 131/211/11/17/190/18 | 22.6644/36.5052/1.9031/2.9412/32.8720/3.1142 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 12345 | Clover/off | P | 228/45/1/101/16/117 | 44.8819/8.8583/0.1969/19.8819/3.1496/23.0315 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 12345 | Clover/off | delta | 97/-166/-10/84/-174/99 | 22.2175/-27.6469/-1.7063/16.9407/-29.7224/19.9173 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 12345 | Clover/on | S | 141/216/6/11/197/16 | 24.0204/36.7973/1.0221/1.8739/33.5605/2.7257 | 42/0/0/0/0/0 | 0/0/0/0/0/0 |
| 12345 | Clover/on | P | 312/28/5/68/4/62 | 65.1357/5.8455/1.0438/14.1962/0.8351/12.9436 | 20/0/0/0/0/0 | 50/0/0/0/0/0 |
| 12345 | Clover/on | delta | 171/-188/-1/57/-193/46 | 41.1153/-30.9518/0.0217/12.3223/-32.7254/10.2179 | -22/0/0/0/0/0 | 50/0/0/0/0/0 |
| 12345 | Borage/off | S | 110/200/4/10/213/18 | 19.8198/36.0360/0.7207/1.8018/38.3784/3.2432 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 12345 | Borage/off | P | 216/29/3/101/22/125 | 43.5484/5.8468/0.6048/20.3629/4.4355/25.2016 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 12345 | Borage/off | delta | 106/-171/-1/91/-191/107 | 23.7286/-30.1893/-0.1159/18.5611/-33.9429/21.9584 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 12345 | Borage/on | S | 124/238/12/9/188/16 | 21.1244/40.5451/2.0443/1.5332/32.0273/2.7257 | 0/42/0/0/0/0 | 0/0/0/0/0/0 |
| 12345 | Borage/on | P | 146/152/0/67/37/69 | 30.9979/32.2718/0.0000/14.2251/7.8556/14.6497 | 0/37/0/0/0/0 | 0/47/0/0/0/0 |
| 12345 | Borage/on | delta | 22/-86/-12/58/-151/53 | 9.8735/-8.2734/-2.0443/12.6918/-24.1716/11.9240 | 0/-5/0/0/0/0 | 0/47/0/0/0/0 |
| 7 | Clover/off | S | 124/191/5/16/223/10 | 21.7926/33.5677/0.8787/2.8120/39.1916/1.7575 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 7 | Clover/off | P | 203/42/3/117/16/107 | 41.5984/8.6066/0.6148/23.9754/3.2787/21.9262 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 7 | Clover/off | delta | 79/-149/-2/101/-207/97 | 19.8057/-24.9611/-0.2640/21.1635/-35.9129/20.1688 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 7 | Clover/on | S | 124/201/11/9/218/13 | 21.5278/34.8958/1.9097/1.5625/37.8472/2.2569 | 63/0/0/0/0/0 | 0/0/0/0/0/0 |
| 7 | Clover/on | P | 290/42/4/91/20/64 | 56.7515/8.2192/0.7828/17.8082/3.9139/12.5245 | 15/0/0/0/0/0 | 72/0/0/0/0/0 |
| 7 | Clover/on | delta | 166/-159/-7/82/-198/51 | 35.2237/-26.6767/-1.1269/16.2457/-33.9333/10.2675 | -48/0/0/0/0/0 | 72/0/0/0/0/0 |
| 7 | Borage/off | S | 132/206/7/8/210/21 | 22.6027/35.2740/1.1986/1.3699/35.9589/3.5959 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 7 | Borage/off | P | 205/43/3/92/23/118 | 42.3554/8.8843/0.6198/19.0083/4.7521/24.3802 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 7 | Borage/off | delta | 73/-163/-4/84/-187/97 | 19.7526/-26.3897/-0.5788/17.6384/-31.2068/20.7843 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 7 | Borage/on | S | 122/221/6/10/217/10 | 20.8191/37.7133/1.0239/1.7065/37.0307/1.7065 | 0/74/0/0/0/0 | 0/0/0/0/0/0 |
| 7 | Borage/on | P | 135/177/0/87/13/75 | 27.7207/36.3450/0.0000/17.8645/2.6694/15.4004 | 0/58/0/0/0/0 | 0/87/0/0/0/0 |
| 7 | Borage/on | delta | 13/-44/-6/77/-204/65 | 6.9016/-1.3683/-1.0239/16.1580/-34.3613/13.6939 | 0/-16/0/0/0/0 | 0/87/0/0/0/0 |
| 2026 | Clover/off | S | 133/185/11/13/229/22 | 22.4283/31.1973/1.8550/2.1922/38.6172/3.7099 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 2026 | Clover/off | P | 193/51/3/113/33/115 | 37.9921/10.0394/0.5906/22.2441/6.4961/22.6378 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 2026 | Clover/off | delta | 60/-134/-8/100/-196/93 | 15.5638/-21.1579/-1.2644/20.0519/-32.1211/18.9278 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 2026 | Clover/on | S | 150/182/9/8/195/18 | 26.6904/32.3843/1.6014/1.4235/34.6975/3.2028 | 72/0/0/0/0/0 | 0/0/0/0/0/0 |
| 2026 | Clover/on | P | 312/36/3/76/9/66 | 62.1514/7.1713/0.5976/15.1394/1.7928/13.1474 | 6/2/0/0/0/0 | 82/0/0/0/0/0 |
| 2026 | Clover/on | delta | 162/-146/-6/68/-186/48 | 35.4610/-25.2130/-1.0038/13.7160/-32.9047/9.9446 | -66/2/0/0/0/0 | 82/0/0/0/0/0 |
| 2026 | Borage/off | S | 116/191/10/6/240/8 | 20.3152/33.4501/1.7513/1.0508/42.0315/1.4011 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 2026 | Borage/off | P | 196/40/2/127/21/100 | 40.3292/8.2305/0.4115/26.1317/4.3210/20.5761 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 2026 | Borage/off | delta | 80/-151/-8/121/-219/92 | 20.0140/-25.2196/-1.3398/25.0809/-37.7105/19.1751 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 2026 | Borage/on | S | 114/234/10/14/210/14 | 19.1275/39.2617/1.6779/2.3490/35.2349/2.3490 | 0/69/0/0/0/0 | 0/0/0/0/0/0 |
| 2026 | Borage/on | P | 169/184/2/67/12/53 | 34.7023/37.7823/0.4107/13.7577/2.4641/10.8830 | 0/56/0/0/0/0 | 0/85/0/0/0/0 |
| 2026 | Borage/on | delta | 55/-50/-8/53/-198/39 | 15.5747/-1.4794/-1.2672/11.4087/-32.7708/8.5340 | 0/-13/0/0/0/0 | 0/85/0/0/0/0 |
| 90210 | Clover/off | S | 122/229/10/8/192/16 | 21.1438/39.6880/1.7331/1.3865/33.2756/2.7730 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 90210 | Clover/off | P | 214/33/3/119/15/120 | 42.4603/6.5476/0.5952/23.6111/2.9762/23.8095 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 90210 | Clover/off | delta | 92/-196/-7/111/-177/104 | 21.3165/-33.1404/-1.1379/22.2246/-30.2994/21.0366 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 90210 | Clover/on | S | 137/227/8/8/187/21 | 23.2993/38.6054/1.3605/1.3605/31.8027/3.5714 | 72/0/0/0/0/0 | 0/0/0/0/0/0 |
| 90210 | Clover/on | P | 318/32/2/68/9/69 | 63.8554/6.4257/0.4016/13.6546/1.8072/13.8554 | 8/0/0/0/0/0 | 75/0/0/0/0/0 |
| 90210 | Clover/on | delta | 181/-195/-6/60/-178/48 | 40.5561/-32.1797/-0.9589/12.2941/-29.9955/10.2840 | -64/0/0/0/0/0 | 75/0/0/0/0/0 |
| 90210 | Borage/off | S | 118/206/14/14/228/27 | 19.4399/33.9374/2.3064/2.3064/37.5618/4.4481 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 90210 | Borage/off | P | 210/33/2/128/15/116 | 41.6667/6.5476/0.3968/25.3968/2.9762/23.0159 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 90210 | Borage/off | delta | 92/-173/-12/114/-213/89 | 22.2268/-27.3898/-1.9096/23.0904/-34.5856/18.5678 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 90210 | Borage/on | S | 124/227/3/16/200/17 | 21.1244/38.6712/0.5111/2.7257/34.0716/2.8961 | 0/54/0/0/0/0 | 0/0/0/0/0/0 |
| 90210 | Borage/on | P | 161/191/2/71/15/57 | 32.3944/38.4306/0.4024/14.2857/3.0181/11.4688 | 0/65/0/0/0/0 | 0/64/0/0/0/0 |
| 90210 | Borage/on | delta | 37/-36/-1/55/-185/40 | 11.2700/-0.2406/-0.1087/11.5600/-31.0534/8.5727 | 0/11/0/0/0/0 | 0/64/0/0/0/0 |
| 555 | Clover/off | S | 128/207/7/6/200/19 | 22.5750/36.5079/1.2346/1.0582/35.2734/3.3510 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 555 | Clover/off | P | 223/31/5/125/25/107 | 43.2171/6.0078/0.9690/24.2248/4.8450/20.7364 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 555 | Clover/off | delta | 95/-176/-2/119/-175/88 | 20.6421/-30.5002/-0.2656/23.1666/-30.4284/17.3855 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 555 | Clover/on | S | 142/199/12/10/196/15 | 24.7387/34.6690/2.0906/1.7422/34.1463/2.6132 | 75/0/0/0/0/0 | 0/0/0/0/0/0 |
| 555 | Clover/on | P | 314/30/1/65/16/74 | 62.8000/6.0000/0.2000/13.0000/3.2000/14.8000 | 8/0/0/0/0/1 | 81/0/0/0/0/0 |
| 555 | Clover/on | delta | 172/-169/-11/55/-180/59 | 38.0613/-28.6690/-1.8906/11.2578/-30.9463/12.1868 | -67/0/0/0/0/1 | 81/0/0/0/0/0 |
| 555 | Borage/off | S | 109/234/7/13/193/11 | 19.2240/41.2698/1.2346/2.2928/34.0388/1.9400 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 555 | Borage/off | P | 232/36/7/92/12/117 | 46.7742/7.2581/1.4113/18.5484/2.4194/23.5887 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 555 | Borage/off | delta | 123/-198/0/79/-181/106 | 27.5502/-34.0118/0.1767/16.2556/-31.6194/21.6487 | 0/0/0/0/0/0 | 0/0/0/0/0/0 |
| 555 | Borage/on | S | 115/218/2/8/228/15 | 19.6246/37.2014/0.3413/1.3652/38.9078/2.5597 | 0/67/0/0/0/0 | 0/0/0/0/0/0 |
| 555 | Borage/on | P | 139/176/3/98/6/70 | 28.2520/35.7724/0.6098/19.9187/1.2195/14.2276 | 0/52/0/0/0/0 | 0/81/0/0/0/0 |
| 555 | Borage/on | delta | 24/-42/1/90/-222/55 | 8.6275/-1.4290/0.2685/18.5535/-37.6883/11.6679 | 0/-15/0/0/0/0 | 0/81/0/0/0/0 |

| Seed | Specialist/flag | Spring replacements | Eligible/all deaths | Seed/seasonal replacements (whole run) | Eligible seed events by species |
| --- | --- | --- | --- | --- | --- |
| 12345 | Clover/off | 192/11/8/132/35/212 | 51/3086 | 0/2794 | 51/0/0/0/0/0 |
| 12345 | Clover/on | 383/10/5/70/14/108 | 70/3115 | 51/2743 | 70/0/0/0/0/0 |
| 12345 | Borage/off | 179/19/6/124/35/227 | 69/3102 | 0/2798 | 0/69/0/0/0/0 |
| 12345 | Borage/on | 90/284/2/70/15/129 | 84/3127 | 38/2760 | 0/84/0/0/0/0 |
| 7 | Clover/off | 173/19/4/152/37/205 | 83/3112 | 0/2800 | 82/1/0/0/0/0 |
| 7 | Clover/on | 391/11/3/78/10/97 | 87/3089 | 72/2728 | 87/0/0/0/0/0 |
| 7 | Borage/off | 177/19/5/119/40/230 | 124/3116 | 0/2800 | 0/124/0/0/0/0 |
| 7 | Borage/on | 75/292/2/80/13/128 | 145/3113 | 70/2730 | 0/145/0/0/0/0 |
| 2026 | Clover/off | 158/20/7/140/37/228 | 92/3081 | 0/2789 | 92/0/0/0/0/0 |
| 2026 | Clover/on | 374/17/2/66/13/118 | 90/3087 | 62/2727 | 88/2/0/0/0/0 |
| 2026 | Borage/off | 162/24/5/147/25/227 | 129/3103 | 0/2789 | 0/129/0/0/0/0 |
| 2026 | Borage/on | 97/318/2/61/15/97 | 141/3102 | 65/2724 | 0/141/0/0/0/0 |
| 90210 | Clover/off | 171/27/9/132/19/232 | 72/3082 | 0/2786 | 72/0/0/0/0/0 |
| 90210 | Clover/on | 379/5/2/68/8/128 | 83/3088 | 66/2720 | 83/0/0/0/0/0 |
| 90210 | Borage/off | 174/13/5/145/44/209 | 85/3078 | 0/2782 | 0/85/0/0/0/0 |
| 90210 | Borage/on | 96/288/2/68/19/117 | 129/3085 | 59/2723 | 0/129/0/0/0/0 |
| 555 | Clover/off | 188/26/5/135/24/212 | 86/3068 | 0/2784 | 85/1/0/0/0/0 |
| 555 | Clover/on | 379/3/5/71/4/128 | 90/3084 | 77/2707 | 89/0/0/0/0/1 |
| 555 | Borage/off | 184/25/2/121/31/227 | 113/3086 | 0/2782 | 0/112/0/0/0/1 |
| 555 | Borage/on | 83/286/3/89/17/112 | 133/3090 | 61/2721 | 0/133/0/0/0/0 |

Logged draw weights are inputs, separate from realised replacements above.
Each bush flower counts as one actual replacement. Three profiles cover all arms:

| Arms | Logged draw weights min:max (species vector) |
| --- | --- |
| 12345 Clover/off, 12345 Borage/off, 7 Clover/off, 7 Borage/off, 2026 Clover/off, 2026 Borage/off, 90210 Clover/off, 90210 Borage/off, 555 Clover/off, 555 Borage/off | 2.4000:35.7238/1.8000:1.8000/0.4800:0.4800/1.3431:21.9992/1.0800:1.0800/2.7461:34.9978 |
| 12345 Clover/on, 7 Clover/on, 2026 Clover/on, 90210 Clover/on, 555 Clover/on | 12.2491:116.4655/1.8000:1.8000/0.4800:0.4800/1.3431:21.9992/1.0800:1.0800/2.7461:34.9978 |
| 12345 Borage/on, 7 Borage/on, 2026 Borage/on, 90210 Borage/on, 555 Borage/on | 2.4000:35.7238/11.6491:88.4110/0.4800:0.4800/1.3431:21.9992/1.0800:1.0800/2.7461:34.9978 |

### Paired effects and specialist contrasts

Effects are seed-set on minus off within specialist and seed. Contrast is
(Borage on - Borage off) - (Clover on - Clover off), calculated per seed.

| Seed | Comparison | Phase | Live count difference | Share difference pp | Seed-ledger difference | Spring-ledger difference |
| --- | --- | --- | --- | --- | --- | --- |
| 12345 | Clover | S | 10/5/-5/-6/7/-2 | 1.3561/0.2921/-0.8810/-1.0672/0.6885/-0.3885 | 42/0/0/0/0/0 | 0/0/0/0/0/0 |
| 12345 | Clover | P | 84/-17/4/-33/-12/-55 | 20.2538/-3.0128/0.8470/-5.6856/-2.3145/-10.0879 | 20/0/0/0/0/0 | 50/0/0/0/0/0 |
| 12345 | Clover | delta | 74/-22/9/-27/-19/-53 | 18.8977/-3.3048/1.7280/-4.6184/-3.0030/-9.6994 | -22/0/0/0/0/0 | 50/0/0/0/0/0 |
| 7 | Clover | S | 0/10/6/-7/-5/3 | -0.2648/1.3282/1.0310/-1.2495/-1.3443/0.4995 | 63/0/0/0/0/0 | 0/0/0/0/0/0 |
| 7 | Clover | P | 87/0/1/-26/4/-43 | 15.1531/-0.3874/0.1680/-6.1672/0.6352/-9.4018 | 15/0/0/0/0/0 | 72/0/0/0/0/0 |
| 7 | Clover | delta | 87/-10/-5/-19/9/-46 | 15.4179/-1.7156/-0.8630/-4.9177/1.9795/-9.9012 | -48/0/0/0/0/0 | 72/0/0/0/0/0 |
| 2026 | Clover | S | 17/-3/-2/-5/-34/-4 | 4.2621/1.1870/-0.2536/-0.7688/-3.9197/-0.5071 | 72/0/0/0/0/0 | 0/0/0/0/0/0 |
| 2026 | Clover | P | 119/-15/0/-37/-24/-49 | 24.1593/-2.8681/0.0071/-7.1047/-4.7032/-9.4904 | 6/2/0/0/0/0 | 82/0/0/0/0/0 |
| 2026 | Clover | delta | 102/-12/2/-32/10/-45 | 19.8972/-4.0551/0.2606/-6.3359/-0.7835/-8.9833 | -66/2/0/0/0/0 | 82/0/0/0/0/0 |
| 90210 | Clover | S | 15/-2/-2/0/-5/5 | 2.1555/-1.0826/-0.3726/-0.0259/-1.4728/0.7985 | 72/0/0/0/0/0 | 0/0/0/0/0/0 |
| 90210 | Clover | P | 104/-1/-1/-51/-6/-51 | 21.3951/-0.1219/-0.1936/-9.9565/-1.1690/-9.9541 | 8/0/0/0/0/0 | 75/0/0/0/0/0 |
| 90210 | Clover | delta | 89/1/1/-51/-1/-56 | 19.2396/0.9607/0.1789/-9.9306/0.3039/-10.7526 | -64/0/0/0/0/0 | 75/0/0/0/0/0 |
| 555 | Clover | S | 14/-8/5/4/-4/-4 | 2.1637/-1.8389/0.8560/0.6840/-1.1270/-0.7377 | 75/0/0/0/0/0 | 0/0/0/0/0/0 |
| 555 | Clover | P | 91/-1/-4/-60/-9/-33 | 19.5829/-0.0078/-0.7690/-11.2248/-1.6450/-5.9364 | 8/0/0/0/0/1 | 81/0/0/0/0/0 |
| 555 | Clover | delta | 77/7/-9/-64/-5/-29 | 17.4192/1.8312/-1.6250/-11.9088/-0.5179/-5.1987 | -67/0/0/0/0/1 | 81/0/0/0/0/0 |
| 12345 | Borage | S | 14/38/8/-1/-25/-2 | 1.3045/4.5091/1.3236/-0.2686/-6.3511/-0.5175 | 0/42/0/0/0/0 | 0/0/0/0/0/0 |
| 12345 | Borage | P | -70/123/-3/-34/15/-56 | -12.5505/26.4250/-0.6048/-6.1379/3.4201/-10.5519 | 0/37/0/0/0/0 | 0/47/0/0/0/0 |
| 12345 | Borage | delta | -84/85/-11/-33/40/-54 | -13.8551/21.9159/-1.9284/-5.8693/9.7713/-10.0344 | 0/-5/0/0/0/0 | 0/47/0/0/0/0 |
| 7 | Borage | S | -10/15/-1/2/7/-11 | -1.7836/2.4393/-0.1747/0.3366/1.0718/-1.8894 | 0/74/0/0/0/0 | 0/0/0/0/0/0 |
| 7 | Borage | P | -70/134/-3/-5/-10/-43 | -14.6346/27.4607/-0.6198/-1.1438/-2.0827/-8.9798 | 0/58/0/0/0/0 | 0/87/0/0/0/0 |
| 7 | Borage | delta | -60/119/-2/-7/-17/-32 | -12.8510/25.0213/-0.4451/-1.4804/-3.1545/-7.0903 | 0/-16/0/0/0/0 | 0/87/0/0/0/0 |
| 2026 | Borage | S | -2/43/0/8/-30/6 | -1.1877/5.8117/-0.0735/1.2982/-6.7966/0.9479 | 0/69/0/0/0/0 | 0/0/0/0/0/0 |
| 2026 | Borage | P | -27/144/0/-60/-9/-47 | -5.6270/29.5519/-0.0008/-12.3740/-1.8569/-9.6932 | 0/56/0/0/0/0 | 0/85/0/0/0/0 |
| 2026 | Borage | delta | -25/101/0/-68/21/-53 | -4.4392/23.7402/0.0726/-13.6722/4.9397/-10.6411 | 0/-13/0/0/0/0 | 0/85/0/0/0/0 |
| 90210 | Borage | S | 6/21/-11/2/-28/-10 | 1.6845/4.7338/-1.7954/0.4193/-3.4902/-1.5520 | 0/54/0/0/0/0 | 0/0/0/0/0/0 |
| 90210 | Borage | P | -49/158/0/-57/0/-59 | -9.2723/31.8830/0.0056/-11.1111/0.0419/-11.5471 | 0/65/0/0/0/0 | 0/64/0/0/0/0 |
| 90210 | Borage | delta | -55/137/11/-59/28/-49 | -10.9568/27.1492/1.8009/-11.5304/3.5321/-9.9950 | 0/11/0/0/0/0 | 0/64/0/0/0/0 |
| 555 | Borage | S | 6/-16/-5/-5/35/4 | 0.4006/-4.0685/-0.8933/-0.9276/4.8690/0.6197 | 0/67/0/0/0/0 | 0/0/0/0/0/0 |
| 555 | Borage | P | -93/140/-4/6/-6/-47 | -18.5222/28.5143/-0.8015/1.3703/-1.1998/-9.3611 | 0/52/0/0/0/0 | 0/81/0/0/0/0 |
| 555 | Borage | delta | -99/156/1/11/-41/-51 | -18.9227/32.5828/0.0917/2.2979/-6.0689/-9.9808 | 0/-15/0/0/0/0 | 0/81/0/0/0/0 |
| 12345 | Borage effect - Clover effect | S | 4/33/13/5/-32/0 | -0.0515/4.2170/2.2045/0.7987/-7.0396/-0.1291 | -42/42/0/0/0/0 | 0/0/0/0/0/0 |
| 12345 | Borage effect - Clover effect | P | -154/140/-7/-1/27/-1 | -32.8043/29.4377/-1.4518/-0.4522/5.7347/-0.4641 | -20/37/0/0/0/0 | -50/47/0/0/0/0 |
| 12345 | Borage effect - Clover effect | delta | -158/107/-20/-6/59/-1 | -32.7528/25.2207/-3.6564/-1.2509/12.7743/-0.3350 | 22/-5/0/0/0/0 | -50/47/0/0/0/0 |
| 7 | Borage effect - Clover effect | S | -10/5/-7/9/12/-14 | -1.5188/1.1112/-1.2057/1.5861/2.4162/-2.3889 | -63/74/0/0/0/0 | 0/0/0/0/0/0 |
| 7 | Borage effect - Clover effect | P | -157/134/-4/21/-14/0 | -29.7877/27.8481/-0.7879/5.0234/-2.7179/0.4220 | -15/58/0/0/0/0 | -72/87/0/0/0/0 |
| 7 | Borage effect - Clover effect | delta | -147/129/3/12/-26/14 | -28.2690/26.7369/0.4179/3.4373/-5.1340/2.8109 | 48/-16/0/0/0/0 | -72/87/0/0/0/0 |
| 2026 | Borage effect - Clover effect | S | -19/46/2/13/4/10 | -5.4498/4.6246/0.1801/2.0670/-2.8769/1.4550 | -72/69/0/0/0/0 | 0/0/0/0/0/0 |
| 2026 | Borage effect - Clover effect | P | -146/159/0/-23/15/2 | -29.7862/32.4199/-0.0079/-5.2693/2.8463/-0.2028 | -6/54/0/0/0/0 | -82/85/0/0/0/0 |
| 2026 | Borage effect - Clover effect | delta | -127/113/-2/-36/11/-8 | -24.3364/27.7953/-0.1880/-7.3363/5.7232/-1.6578 | 66/-15/0/0/0/0 | -82/85/0/0/0/0 |
| 90210 | Borage effect - Clover effect | S | -9/23/-9/2/-23/-15 | -0.4710/5.8164/-1.4228/0.4452/-2.0174/-2.3505 | -72/54/0/0/0/0 | 0/0/0/0/0/0 |
| 90210 | Borage effect - Clover effect | P | -153/159/1/-6/6/-8 | -30.6674/32.0049/0.1992/-1.1546/1.2109/-1.5930 | -8/65/0/0/0/0 | -75/64/0/0/0/0 |
| 90210 | Borage effect - Clover effect | delta | -144/136/10/-8/29/7 | -30.1964/26.1885/1.6220/-1.5999/3.2283/0.7575 | 64/11/0/0/0/0 | -75/64/0/0/0/0 |
| 555 | Borage effect - Clover effect | S | -8/-8/-10/-9/39/8 | -1.7631/-2.2295/-1.7493/-1.6115/5.9961/1.3574 | -75/67/0/0/0/0 | 0/0/0/0/0/0 |
| 555 | Borage effect - Clover effect | P | -184/141/0/66/3/-14 | -38.1051/28.5220/-0.0325/12.5951/0.4451/-3.4246 | -8/52/0/0/0/-1 | -81/81/0/0/0/0 |
| 555 | Borage effect - Clover effect | delta | -176/149/10/75/-36/-22 | -36.3420/30.7516/1.7168/14.2067/-5.5510/-4.7821 | 67/-15/0/0/0/-1 | -81/81/0/0/0/0 |

| Seed | Comparison | Spring replacement difference |
| --- | --- | --- |
| 12345 | Clover | 191/-1/-3/-62/-21/-104 |
| 7 | Clover | 218/-8/-1/-74/-27/-108 |
| 2026 | Clover | 216/-3/-5/-74/-24/-110 |
| 90210 | Clover | 208/-22/-7/-64/-11/-104 |
| 555 | Clover | 191/-23/0/-64/-20/-84 |
| 12345 | Borage | -89/265/-4/-54/-20/-98 |
| 7 | Borage | -102/273/-3/-39/-27/-102 |
| 2026 | Borage | -65/294/-3/-86/-10/-130 |
| 90210 | Borage | -78/275/-3/-77/-25/-92 |
| 555 | Borage | -101/261/1/-32/-14/-115 |
| 12345 | Borage effect - Clover effect | -280/266/-1/8/1/6 |
| 7 | Borage effect - Clover effect | -320/281/-2/35/0/6 |
| 2026 | Borage effect - Clover effect | -281/297/2/-12/14/-20 |
| 90210 | Borage effect - Clover effect | -286/297/4/-13/-14/12 |
| 555 | Borage effect - Clover effect | -292/284/1/32/6/-31 |

### Defined-pair summaries

Every vector element is **median [minimum, maximum]; n** for that species.
Each n is five defined pairs, or five arms in within-arm summaries.

**Clover**

| Phase / measurement | Species vector: median [min, max]; n |
| --- | --- |
| summer/live_by_species | 14 [0, 17]; 5 / -2 [-8, 10]; 5 / -2 [-5, 6]; 5 / -5 [-7, 4]; 5 / -5 [-34, 7]; 5 / -2 [-4, 5]; 5 |
| summer/shares | 2.1555 [-0.2648, 4.2621]; 5 / 0.2921 [-1.8389, 1.3282]; 5 / -0.2536 [-0.8810, 1.0310]; 5 / -0.7688 [-1.2495, 0.6840]; 5 / -1.3443 [-3.9197, 0.6885]; 5 / -0.3885 [-0.7377, 0.7985]; 5 |
| summer/seed_counts | 72 [42, 75]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 |
| summer/spring_counts | 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 |
| spring/live_by_species | 91 [84, 119]; 5 / -1 [-17, 0]; 5 / 0 [-4, 4]; 5 / -37 [-60, -26]; 5 / -9 [-24, 4]; 5 / -49 [-55, -33]; 5 |
| spring/shares | 20.2538 [15.1531, 24.1593]; 5 / -0.3874 [-3.0128, -0.0078]; 5 / 0.0071 [-0.7690, 0.8470]; 5 / -7.1047 [-11.2248, -5.6856]; 5 / -1.6450 [-4.7032, 0.6352]; 5 / -9.4904 [-10.0879, -5.9364]; 5 |
| spring/seed_counts | 8 [6, 20]; 5 / 0 [0, 2]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 1]; 5 |
| spring/spring_counts | 75 [50, 82]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 |
| summer_to_spring/live_by_species | 87 [74, 102]; 5 / -10 [-22, 7]; 5 / 1 [-9, 9]; 5 / -32 [-64, -19]; 5 / -1 [-19, 10]; 5 / -46 [-56, -29]; 5 |
| summer_to_spring/shares | 18.8977 [15.4179, 19.8972]; 5 / -1.7156 [-4.0551, 1.8312]; 5 / 0.1789 [-1.6250, 1.7280]; 5 / -6.3359 [-11.9088, -4.6184]; 5 / -0.5179 [-3.0030, 1.9795]; 5 / -9.6994 [-10.7526, -5.1987]; 5 |
| summer_to_spring/seed_counts | -64 [-67, -22]; 5 / 0 [0, 2]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 1]; 5 |
| summer_to_spring/spring_counts | 75 [50, 82]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 |
| spring replacements | 208 [191, 218]; 5 / -8 [-23, -1]; 5 / -3 [-7, 0]; 5 / -64 [-74, -62]; 5 / -21 [-27, -11]; 5 / -104 [-110, -84]; 5 |

**Borage**

| Phase / measurement | Species vector: median [min, max]; n |
| --- | --- |
| summer/live_by_species | 6 [-10, 14]; 5 / 21 [-16, 43]; 5 / -1 [-11, 8]; 5 / 2 [-5, 8]; 5 / -25 [-30, 35]; 5 / -2 [-11, 6]; 5 |
| summer/shares | 0.4006 [-1.7836, 1.6845]; 5 / 4.5091 [-4.0685, 5.8117]; 5 / -0.1747 [-1.7954, 1.3236]; 5 / 0.3366 [-0.9276, 1.2982]; 5 / -3.4902 [-6.7966, 4.8690]; 5 / -0.5175 [-1.8894, 0.9479]; 5 |
| summer/seed_counts | 0 [0, 0]; 5 / 67 [42, 74]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 |
| summer/spring_counts | 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 |
| spring/live_by_species | -70 [-93, -27]; 5 / 140 [123, 158]; 5 / -3 [-4, 0]; 5 / -34 [-60, 6]; 5 / -6 [-10, 15]; 5 / -47 [-59, -43]; 5 |
| spring/shares | -12.5505 [-18.5222, -5.6270]; 5 / 28.5143 [26.4250, 31.8830]; 5 / -0.6048 [-0.8015, 0.0056]; 5 / -6.1379 [-12.3740, 1.3703]; 5 / -1.1998 [-2.0827, 3.4201]; 5 / -9.6932 [-11.5471, -8.9798]; 5 |
| spring/seed_counts | 0 [0, 0]; 5 / 56 [37, 65]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 |
| spring/spring_counts | 0 [0, 0]; 5 / 81 [47, 87]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 |
| summer_to_spring/live_by_species | -60 [-99, -25]; 5 / 119 [85, 156]; 5 / 0 [-11, 11]; 5 / -33 [-68, 11]; 5 / 21 [-41, 40]; 5 / -51 [-54, -32]; 5 |
| summer_to_spring/shares | -12.8510 [-18.9227, -4.4392]; 5 / 25.0213 [21.9159, 32.5828]; 5 / 0.0726 [-1.9284, 1.8009]; 5 / -5.8693 [-13.6722, 2.2979]; 5 / 3.5321 [-6.0689, 9.7713]; 5 / -9.9950 [-10.6411, -7.0903]; 5 |
| summer_to_spring/seed_counts | 0 [0, 0]; 5 / -13 [-16, 11]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 |
| summer_to_spring/spring_counts | 0 [0, 0]; 5 / 81 [47, 87]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 |
| spring replacements | -89 [-102, -65]; 5 / 273 [261, 294]; 5 / -3 [-4, 1]; 5 / -54 [-86, -32]; 5 / -20 [-27, -10]; 5 / -102 [-130, -92]; 5 |

**Borage effect - Clover effect**

| Phase / measurement | Species vector: median [min, max]; n |
| --- | --- |
| summer/live_by_species | -9 [-19, 4]; 5 / 23 [-8, 46]; 5 / -7 [-10, 13]; 5 / 5 [-9, 13]; 5 / 4 [-32, 39]; 5 / 0 [-15, 10]; 5 |
| summer/shares | -1.5188 [-5.4498, -0.0515]; 5 / 4.2170 [-2.2295, 5.8164]; 5 / -1.2057 [-1.7493, 2.2045]; 5 / 0.7987 [-1.6115, 2.0670]; 5 / -2.0174 [-7.0396, 5.9961]; 5 / -0.1291 [-2.3889, 1.4550]; 5 |
| summer/seed_counts | -72 [-75, -42]; 5 / 67 [42, 74]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 |
| summer/spring_counts | 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 |
| spring/live_by_species | -154 [-184, -146]; 5 / 141 [134, 159]; 5 / 0 [-7, 1]; 5 / -1 [-23, 66]; 5 / 6 [-14, 27]; 5 / -1 [-14, 2]; 5 |
| spring/shares | -30.6674 [-38.1051, -29.7862]; 5 / 29.4377 [27.8481, 32.4199]; 5 / -0.0325 [-1.4518, 0.1992]; 5 / -0.4522 [-5.2693, 12.5951]; 5 / 1.2109 [-2.7179, 5.7347]; 5 / -0.4641 [-3.4246, 0.4220]; 5 |
| spring/seed_counts | -8 [-20, -6]; 5 / 54 [37, 65]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [-1, 0]; 5 |
| spring/spring_counts | -75 [-82, -50]; 5 / 81 [47, 87]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 |
| summer_to_spring/live_by_species | -147 [-176, -127]; 5 / 129 [107, 149]; 5 / 3 [-20, 10]; 5 / -6 [-36, 75]; 5 / 11 [-36, 59]; 5 / -1 [-22, 14]; 5 |
| summer_to_spring/shares | -30.1964 [-36.3420, -24.3364]; 5 / 26.7369 [25.2207, 30.7516]; 5 / 0.4179 [-3.6564, 1.7168]; 5 / -1.2509 [-7.3363, 14.2067]; 5 / 3.2283 [-5.5510, 12.7743]; 5 / -0.3350 [-4.7821, 2.8109]; 5 |
| summer_to_spring/seed_counts | 64 [22, 67]; 5 / -15 [-16, 11]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [-1, 0]; 5 |
| summer_to_spring/spring_counts | -75 [-82, -50]; 5 / 81 [47, 87]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 |
| spring replacements | -286 [-320, -280]; 5 / 284 [266, 297]; 5 / 1 [-2, 4]; 5 / 8 [-13, 35]; 5 / 1 [-14, 14]; 5 / 6 [-31, 12]; 5 |

### Within-arm summer-to-spring summaries

Seasonal changes below are separate from on-minus-off effects. Raw changes
for every arm appear above; each summary uses five arms.

| Clover/off measurement | Species vector: median [min, max]; n |
| --- | --- |
| live_by_species | 92 [60, 97]; 5 / -166 [-196, -134]; 5 / -7 [-10, -2]; 5 / 101 [84, 119]; 5 / -177 [-207, -174]; 5 / 97 [88, 104]; 5 |
| shares | 20.6421 [15.5638, 22.2175]; 5 / -27.6469 [-33.1404, -21.1579]; 5 / -1.1379 [-1.7063, -0.2640]; 5 / 21.1635 [16.9407, 23.1666]; 5 / -30.4284 [-35.9129, -29.7224]; 5 / 19.9173 [17.3855, 21.0366]; 5 |
| seed_counts | 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 |
| spring_counts | 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 |

| Clover/on measurement | Species vector: median [min, max]; n |
| --- | --- |
| live_by_species | 171 [162, 181]; 5 / -169 [-195, -146]; 5 / -6 [-11, -1]; 5 / 60 [55, 82]; 5 / -186 [-198, -178]; 5 / 48 [46, 59]; 5 |
| shares | 38.0613 [35.2237, 41.1153]; 5 / -28.6690 [-32.1797, -25.2130]; 5 / -1.0038 [-1.8906, 0.0217]; 5 / 12.3223 [11.2578, 16.2457]; 5 / -32.7254 [-33.9333, -29.9955]; 5 / 10.2675 [9.9446, 12.1868]; 5 |
| seed_counts | -64 [-67, -22]; 5 / 0 [0, 2]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 1]; 5 |
| spring_counts | 75 [50, 82]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 |

| Borage/off measurement | Species vector: median [min, max]; n |
| --- | --- |
| live_by_species | 92 [73, 123]; 5 / -171 [-198, -151]; 5 / -4 [-12, 0]; 5 / 91 [79, 121]; 5 / -191 [-219, -181]; 5 / 97 [89, 107]; 5 |
| shares | 22.2268 [19.7526, 27.5502]; 5 / -27.3898 [-34.0118, -25.2196]; 5 / -0.5788 [-1.9096, 0.1767]; 5 / 18.5611 [16.2556, 25.0809]; 5 / -33.9429 [-37.7105, -31.2068]; 5 / 20.7843 [18.5678, 21.9584]; 5 |
| seed_counts | 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 |
| spring_counts | 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 |

| Borage/on measurement | Species vector: median [min, max]; n |
| --- | --- |
| live_by_species | 24 [13, 55]; 5 / -44 [-86, -36]; 5 / -6 [-12, 1]; 5 / 58 [53, 90]; 5 / -198 [-222, -151]; 5 / 53 [39, 65]; 5 |
| shares | 9.8735 [6.9016, 15.5747]; 5 / -1.4290 [-8.2734, -0.2406]; 5 / -1.0239 [-2.0443, 0.2685]; 5 / 12.6918 [11.4087, 18.5535]; 5 / -32.7708 [-37.6883, -24.1716]; 5 / 11.6679 [8.5340, 13.6939]; 5 |
| seed_counts | 0 [0, 0]; 5 / -13 [-16, 11]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 |
| spring_counts | 0 [0, 0]; 5 / 81 [47, 87]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 / 0 [0, 0]; 5 |

### Coverage and interpretation

All twenty arms cover eligible and ineligible deaths and seasonal replacements.
All ten enabled arms record actual seed replacements. Eligible seed events cover
Clover and Borage, with two isolated Dandelion events across the campaign.
No Foxglove, Poppy or Bramble seed events were observed. Eligibility is the logged
sets_seed condition even when seed-set is disabled. Missing biological coverage
limits claims for those species rather than proving no effect.

Within this fixture, specialist choice steers realised next-spring composition.
Seed-set raises Clover share in all five Clover-specialist pairs: median
+20.2538 pp, range +15.1531 to +24.1593; live Clover rises by 84 to 119
(median 91), and spring Clover replacements rise by 191 to 218 (median 208).
With Borage specialists, Borage share rises in all five pairs: median +28.5143 pp,
range +26.4250 to +31.8830; live Borage rises by 123 to 158 (median 140),
and spring Borage replacements rise by 261 to 294 (median 273).

The Borage-minus-Clover effect contrast is positive for Borage share in all
five seeds: median +29.4377 pp, range +27.8481 to +32.4199. The Clover share
contrast is negative in all five: median -30.6674 pp, range -38.1051 to -29.7862.
Median replacement contrasts are +284 Borage and -286 Clover. The direction
follows specialist assignment in these runs; matched disabled controls account
for specialist and seasonal effects rather than attributing every change to seed-set.

Matched seeds do not guarantee identical random draws after treatments diverge.
These are descriptive comparisons, not confidence intervals or an effect threshold.
The supported workforce, food and accelerated calendar establish neither ordinary
pacing, ordinary-run survival nor ordinary-run effect size. Replacements during
spring differ from the final live population because flowers can die or be replaced
before day 25. Draw weights are neither final populations nor replacement counts.

No balance, ecology, save or UI change follows from this measurement. A future
UI claim or balance proposal needs its own explicit design decision; no follow-up
slice is automatic. Retain this reference and external artefacts, reopening only
for a new specific ecology question.

The twenty-arm campaign, sixteen reporter unit tests, source checks, documentation
checks and prefinish boot pass. No hands-on check is required for this offline
evidence-only slice.
