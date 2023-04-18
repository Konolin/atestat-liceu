uses crt, graph;

type vec_xy = array[1..2] of integer;

const
	x = 639; {latime ecran in pixeli (0 - 639)}
	y = 479; {inaltime ecran in pixeli (0 - 479)}
	lmax : integer = 6; {lungimea initiala a sarpelui}
	l : integer = 1;
	mort : boolean = false;
	viteza : byte = 8;
	scor : longint = 0;
	cul_sarpe = 2;
	cul_fundal = 8;

var
	xm, ym : integer;
	cap, coada : vec_xy;



{modifica viteza in functie de scor}
procedure dificultate(scor : longint; var viteza : byte);
begin
	if (scor >= 500) and (scor < 1000) then viteza := 5
	else 
		if (scor >= 1000) and (scor < 1500) then viteza := 3
		else viteza := 1;
end;



procedure update_scor;
var scor_str : string;
begin
	{scorul este marit cu 100}
	inc(scor, 100);

	{se acopera scorul vechi cu o bara neagra}
	setfillstyle(1, 0); bar(45, 0, x, 12);

	{se afiseaza noul scor pe ecran}
	str(scor, scor_str);
	setcolor(15); outtextxy(45, 1, scor_str);
end;



procedure creare_mar;
	procedure graph_mar(x, y : integer);
	begin
		{crearea texturii marului, cu punctul de coordonate x, y in mijloc}
		setfillstyle(1, 0);       setcolor(0);
		bar(x-5, y-1, x+5, y+3);  line(x-4, y+4, x+4, y+4);
		line(x-3, y+5, x+3, y+5); line(x-2, y+6, x+2, y+6);
		putpixel(x-4, y-2, 0);    putpixel(x-3, y-3, 0);
		setfillstyle(1, 4);       setcolor(4);
		bar(x-4, y-1, x+4, y+3);  line(x-3, y+4, x+3, y+4);
		line(x-2, y+5, x-1, y+5); line(x+1, y+5, x+2, y+5);
		line(x-3, y-2, x-2, y-2); setfillstyle(1, 0);
		bar(x-2, y-5, x, y-2);    bar(x+1, y-4, x+4, y-1);
		bar(x+3, y-3, x+6, y);    setfillstyle(1, 2);
		bar(x+1, y-3, x+3, y-2);  bar(x+3, y-2, x+5, y-1);
		setfillstyle(1, 6);       line(x-1, y-6, x-1, y-3);
		putpixel(x-1, y-6, 0);    putpixel(x, y+6, cul_fundal);
	end;

begin
	{se repeta generarea pozitiei pana la gasirea unei pozitii valide}
	{terenul de joc este separat in mai multe partare}
	{terenul contine 42x31 patrate, cu marimea de 15x15 pixeli}
	{random(x) => (0, ..., x - 1) => random(x) + 1 => (1, ..., x)}
	{*15 transforma pozitia in pixeli}
	{-3/+6 sunt folosite pentru a centra marul in mijlocul patratului}
	repeat
		xm := (random(42) + 1) * 15 - 3;
		ym := (random(31) + 1) * 15 + 6;
	until getpixel(xm, ym) <> cul_sarpe;
	
	{se afiseaza textura marului in coordonatele generate mai sus}
	graph_mar(xm, ym);
end;



{se verifica daca pozitia capului coincide cu pozitia marului}
{cap[1] si cap[2] reprezinta coordonatele capului sarpelui}
function mancat(var lmax : integer) : boolean;
begin
	if (cap[1] = xm) and (cap[2] = ym) then
		begin
			mancat := true;
			update_scor;
			inc(lmax, 2);
			dificultate(scor, viteza);
		end
	else mancat := false;
end;



{se verifica daca sarpele a iesit din teren}
function lovit_perimetru : boolean;
begin
	if (cap[1] < 4) or (cap[1] > x - 4) or (cap[2] < 13) or (cap[2] > y) then 
		lovit_perimetru := true
	else lovit_perimetru := false;
end;



{'getpixel(x, y) = cul_sarpe' verifica daca culoarea pixelul din x, y coincide cea a sarpelui}
{daca ele coincid atunci urmatoarea miscare va rezulta intr-o colizie}
{'input' este folosit pentru a determina directia in care trebuie facuta verificarea}
function colizie(input : char):  boolean;
var auxcol : boolean;
begin
	auxcol := false;
	case input of
		'w' : if getpixel(cap[1], cap[2] - 9) = cul_sarpe then auxcol := true;
		's' : if getpixel(cap[1], cap[2] + 9) = cul_sarpe then auxcol := true;
		'a' : if getpixel(cap[1] - 9, cap[2]) = cul_sarpe then auxcol := true;
		'd' : if getpixel(cap[1] + 9, cap[2]) = cul_sarpe then auxcol := true;
	end;
	colizie:=auxcol;
end;



{determina pozitia ultimului segment fara de penultimul segment}
{1 : sub; 2 : sus; 3 : dreapta; 4 : stanga}
{se verifica cate 2 pixeli in fiecare directie} 
{daca ei au aceeasi culoare cu sarpele, atunci se sterge segmentul din partea opusa}
function caz_stergere: integer;
begin
	if (getpixel(coada[1], coada[2] - 9) = cul_sarpe) and
	(getpixel(coada[1], coada[2] - 8) = cul_sarpe) then caz_stergere := 1
	else
		if (getpixel(coada[1], coada[2] + 9) = cul_sarpe) and
		(getpixel(coada[1], coada[2] + 8) = cul_sarpe) then caz_stergere := 2
		else
			if (getpixel(coada[1] - 9, coada[2]) = cul_sarpe) and
			(getpixel(coada[1] - 8, coada[2]) = cul_sarpe) then caz_stergere := 3
			else caz_stergere := 4;
end;



{input = w, a, s, d}
{xy_cap - tipul de miscare (1 = orizontala; 2 = vericala)}
{fac_miscare - factorul de miscare (+/- 15)}
procedure miscare(input : char; xy_cap, fac_misc : integer);
var i, caz : integer;
	sterge : boolean;
begin
	repeat
		if colizie(input) then mort := true;
		if mancat(lmax) then creare_mar;
		
		{actualizarea pozitiei capului in functie de input}
		inc(cap[xy_cap], fac_misc);
		if lovit_perimetru then break;
		
		{daca sarpele a mancat un mar, atunci devine 'lmax' mai mare decat 'l'}
		{daca 'l' < 'lmax', atunci ultimul segment al sarpelui nu este sters, pentru a mari lungimea acestuia}
		{caca 'l' = 'lmax', atunci se sterge ultimul segment}
		sterge := false;
		if l < lmax then inc(l)
		else
			begin
				sterge := true;
				caz := caz_stergere;
			end;
		
		{"for" este folosit pentru a sterge si a afisa segmentele doar cu 1 pixel pe rand}
		for i := 0 to 14 do
			begin
				{afisarea segemntului capului}
				setcolor(cul_sarpe);
				case input of
					'w' : line(cap[1]-6, cap[2]+8-i, cap[1]+6, cap[2]+8-i);
					's' : line(cap[1]-6, cap[2]-8+i, cap[1]+6, cap[2]-8+i);
					'a' : line(cap[1]+8-i, cap[2]-6, cap[1]+8-i, cap[2]+6);
					'd' : line(cap[1]-8+i, cap[2]-6, cap[1]-8+i, cap[2]+6);
				end;

				{stergerea cozii daca sterge=true}
				setcolor(cul_fundal);
				if sterge then
					case caz of
						1 : line(coada[1]-6, coada[2]+8-i, coada[1]+6, coada[2]+8-i);
						2 : line(coada[1]-6, coada[2]-8+i, coada[1]+6, coada[2]-8+i);
						3 : line(coada[1]+8-i, coada[2]-6, coada[1]+8-i, coada[2]+6);
						4 : line(coada[1]-8+i, coada[2]-6, coada[1]-8+i, coada[2]+6);
					end;

				{in caz ca se sterge perimetrul, el este afisat din nou}
				setcolor(15); rectangle(4, 13, x-4, y);
				delay(viteza);
			end;

		if sterge then
			begin
				{se sterge excestul creat la schimbarea de directii}
				setfillstyle(1, cul_fundal); bar(coada[1]-8, coada[2]-8, coada[1]+8, coada[2]+8);
				
				{actualizarea pozitiei cozii}
				case caz of
					1: dec(coada[2], 15);
					2: inc(coada[2], 15);
					3: dec(coada[1], 15);
					4: inc(coada[1], 15);
				end; 
			end;
	until keypressed or mort;
end;



procedure gameover(scor : longint);
var scor_str : string;
begin
	{creare ecran negru}
	setfillstyle(1, 0); bar(0, 0, x, y);
	
	{afisarea scorului final}
	setcolor(15); outtextxy(250, 220, 'Scor:');
	str(scor, scor_str); outtextxy(250, 240, scor_str);
	if scor = 130200 then outtextxy(250, 190, 'Ai castigat!');

	{dupa 3 secunde se inchide jocul}
	delay(3000);
	halt;
end;



{input_pre = inputul precedent}
procedure input_miscare(input_pre : char);
var input : char;
begin
	input := readkey;

	{in caz ca inputul este o liteara mare, inputul va fi transformat intr-o litera mica}
	if input = upcase(input) then input := chr(ord(input) + 32);

	{daca 'input' este diferit de 'w', 'a', 's', 'd', atunci se pastreaza 'input_pre'}
	if pos(input, 'wasd') = 0 then input := input_pre;
	
	{nu lasa jucatorul sa faca o intoarcere de 180 de grade dintr-o singura miscare}
	case input of
		'w' : if input_pre = 's' then input := input_pre;
		's' : if input_pre = 'w' then input := input_pre;
		'a' : if input_pre = 'd' then input := input_pre;
		'd' : if input_pre = 'a' then input := input_pre;
	end;
	
	{determina in ce directie se va misca sarpele}
	case input of
		'w' : miscare(input, 2, -15);
		's' : miscare(input, 2, 15);
		'a' : miscare(input, 1, -15);
		'd' : miscare(input, 1, 15);
	end;
	
	if lovit_perimetru or mort then gameover(scor)
	else input_miscare(input);
end;



procedure initializare;
	procedure initgr;
	var gd, gm : integer;
	begin
		{graphic driver: VGA; graphic mode: VGAhi; (640x480 pixeli, 16 culori)}
		gd := VGA; gm := VGAHi;
		initgraph(gd, gm, '');
	end;

	procedure initjoc;
	var scor_str : string;
	begin
		{tine afisat ecranul de start pana se apasa ceva}
		outtextxy(x div 2 - 20, y div 2 - 10, 'Snake');
		outtextxy(x div 3 + 50, y div 2 + 20, 'Mandru Catalin');
		repeat
		until keypressed;

		{init dificultate}
		dificultate(scor, viteza);
			
		{init teren}
		setfillstyle(1, 0); bar(0, 0, x, y);
		setcolor(15); rectangle(4, 13, x-4, y);
		setfillstyle(1, cul_fundal); bar(5, 14, x-5, y-1);
		creare_mar;

		{init scor}
		str(scor, scor_str);
		setcolor(15);
		outtextxy(4, 1, 'Scor: '); outtextxy(45, 1, scor_str);

		{init cap si coada in mijlocul terenului}
		cap[1] := 312; cap[2] := 246;
		coada[1] := 312; coada[2] := 246;
	end;

begin
	clrscr; randomize;
	initgr; initjoc;
	{se incepe cu inputul 'h' pentru a lasa jucatorul sa aleaga in ce directie vrea sa inceapa}
	input_miscare('h');
end;



{PP}
begin
	initializare;
	closegraph;
end.
