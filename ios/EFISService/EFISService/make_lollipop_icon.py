from PIL import Image, ImageDraw, ImageFilter
from pathlib import Path
p = Path(__file__).parent / "Assets.xcassets" / "AppIcon.appiconset"
p.mkdir(parents=True, exist_ok=True)
S = 1024
im = Image.new("RGB", (S,S), (154,0,14))
d = ImageDraw.Draw(im)
for y in range(S):
    t=y/S
    d.line((0,y,S,y), fill=(int(215-95*t), int(7-7*t), int(20-5*t)))
# shadow and white stick
d.ellipse((262,130,786,654),fill=(95,0,12))
d.line((575,565,730,855),fill=(95,0,15),width=90)
d.line((562,548,715,838),fill=(246,246,245),width=68)
d.line((555,550,704,827),fill=(218,223,226),width=15)
# round candy with glossy highlight
d.ellipse((238,105,760,625),fill=(255,87,99),outline=(255,218,220),width=19)
d.ellipse((267,133,733,598),fill=(227,0,28),outline=(255,130,142),width=12)
d.ellipse((300,165,693,553),fill=(237,11,37))
d.arc((318,167,640,445),185,270,fill=(255,214,220),width=33)
d.ellipse((343,184,408,237),fill=(255,230,233))
d.arc((276,213,722,575),12,164,fill=(255,119,130),width=14)
im.save(p/"Lollipop.png")
print(p/"Lollipop.png")
