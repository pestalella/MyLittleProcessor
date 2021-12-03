Aviam com explico això que estic fent. Tot va començar quan volia reproduir 
alguns exercicis que vaig feer quan estudiava a la FIB sobre com sumar números
amb un circuit digital. Quan treballes amb base 2, les úniques xifres que fas
servir per representar números són el 0 i l'1, cosa que simplifica força les 
operacions aritmètiques com la suma:
0+0 -> 0
0+1 -> 1
1+0 -> 1
1+1 -> 10
Sí, en el cas de 1+1 necessitem una xifra més per representar el ròssec del resultat. 
Quan tens números de més d'una xifra sumem com sempre, tenint en compte el ròssec de la
suma de bits anterior:  100+11 -> 111, 110+10 -> 1000
Sumador parcial, sumador complet
Per implementar això en un circuit digital només cal fer un sumador d'un bit
que agafi a més a més el bit de ròssec del sumador al seu costat.

sumadors: RCA, CLA...
Tens moltes opcions, unes més ràpides i complexes, les 
altres més senzilles

ALU: sumes, restes, shifts, ops logiques

I on guardem els resultats? I d'on treiem els operands?
BANC DE REGISTRES

Qui controla el que toca fer? Una unitat de control, que indica al banc de registres
quins operands ha de posar a disposició de la ALU i a quinregistre haurà de guardar
el resultat i també indica a la ALU quina operació realitzar.

I com li direm a la unitat de control què ha d'anar fent? Ho llegirà d'un seguit d'instruccions
que llegirà de la memòria. Definir un seguit d'instruccions que podem necessitar.
Ara en direm unitat d'execució, que llegeix instruccions i les executa (no! no els fot un tret al cap! realitza l'operació que indica cada instrucció)

Demana a la memòria que li doni la primera meitat de la instrucció (el canal de comunicacions amb la memòria és de només 8 bits d'amplada, i les instruccions són totes de 16 bits)
Al següent cicle li arriba la primera meitat de la instrucció i demana la segona meitat. Al següent cicle
arriba la segona meitat de la intstrucció i pot demanar al banc de registres els registres que necessitarà
llegir i escriure per realitzar l'operació. Al següent cicle
