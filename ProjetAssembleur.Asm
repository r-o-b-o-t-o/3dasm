.386
.model flat,stdcall 
option casemap:none
WinMain proto :DWORD,:DWORD,:DWORD,:DWORD

include \masm32\include\windows.inc 
include \masm32\include\gdi32.inc
include \masm32\include\user32.inc 
include \masm32\include\kernel32.inc 

includelib \masm32\lib\gdi32.lib
includelib \masm32\lib\user32.lib 
includelib \masm32\lib\kernel32.lib
include masm32.inc
includelib masm32.lib

.const
	largeur	equ	600
	hauteur	equ	600

.data
	ps			PAINTSTRUCT	<0>
	hdc			HDC	0
	ClassName	db 	"Parent Claas Name",0
	ClassName_F db 	"SimpleWinClass",0 	; classe de type SimpleWinClass (fenêtre simple)
	AppName  	db 	"Moteur 3D",0
	crlf		db  10,0
	space		db	"   ",0
	offX		dd	300
	offY		dd	300
	offZ		dd	400
	rotX		dd 0
	rotY		dd 0
	rotZ		dd 0
	angle		dd 0 ; angle en degrés, indice des tableaux sinus et cosinus
	distFocale REAL8 250.0

.data?
	x			REAL8 ?
	y			REAL8 ?
	flottant	REAL8 ?
	cosinus		REAL8 360 dup(?)
	sinus		REAL8 360 dup(?)
	hInstance 	HINSTANCE ?
	CommandLine	LPSTR ?
	x2			dd ?
	y2			dd ?
	z2			dd ?

.const

.code
start: 
	trigo:
		fldpi	; st0 = PI
		fimul angle	; st0 = PI*angle
		push angle
		mov angle, 180
		fidiv angle	; st0 = (PI*angle)/180=angle en radians
		pop angle
		fsincos		; st0 = cos(angleradian), st1=sin(angleradian)
		
		mov ecx,angle	; ecx=angle
		
		; récupération sur les registres FPU des valeurs et rangement dans les tableaux
		fstp cosinus[ecx*REAL8] ; cosinus[REAL8*angle]=st0=cos(angle) puis st0=sin(angle)
		fstp sinus[ecx*REAL8] ; sinus[REAL8*angle]=st0=sin(angle) puis st0 vide
		
		inc angle	; angle=angle+1
		cmp angle,360
	jb trigo	; si angle<360, aller à trigo

    invoke GetModuleHandle, NULL 
    mov    hInstance,eax 
    invoke GetCommandLine
    mov CommandLine,eax 
    invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT 
    invoke ExitProcess,eax

WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD 
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    
    mov   	wc.cbSize, SIZEOF WNDCLASSEX	; taille de la structure de la window class
	mov   	wc.style, CS_HREDRAW or CS_VREDRAW ; style de la fenêtre : redessinée si redim. ou mouv. horizontal ou vertical
	mov   	wc.lpfnWndProc, OFFSET WndProc	;pointeur vers la fonction de gestion de la fenêtre
	mov   	wc.cbClsExtra, NULL	; nombre de bits supplémentaires à allouer après la window class
	mov   	wc.cbWndExtra, NULL	; nombre de bits supplémentaires à allouer après l'instance de fenêtre
	push  	hInst 
    pop   	wc.hInstance ; un handle de l'instance qui contient la fonction de gestion de la fenêtre
	mov   	wc.hbrBackground, COLOR_WINDOW + 1	; handle de la class background brush utilisé pour le fond de la fenêtre
	mov   	wc.lpszMenuName, NULL	; pointeur vers une chaîne précisant le nom de la ressource menu name
	mov   	wc.lpszClassName, OFFSET ClassName ; pointeur vers le nom de la classe de la fenêtre
	
    invoke 	LoadIcon, NULL, IDI_APPLICATION ; arg1=handle vers le module contenant l'icone à charger, NULL pour une icone prédéfinie, arg2=nom del'icone à charger ou icone prédéfinie 
	
	mov   	wc.hIcon, eax	; un handle de la classe icon (vers une ressource de type icon)
	mov   	wc.hIconSm, eax	; un handle de la classe small icon (vers une ressource de type icon)
	
	invoke 	LoadCursor, NULL, IDC_ARROW	; arg1=handle vers le module contenant le curseur à charger, NULL pour un curseur prédéfini, arg2=nom du curseur à charger ou curseur prédéfini
	
	mov   	wc.hCursor, eax	; un handle de la classe cursor (vers une ressource de type cursor)
	
	invoke 	RegisterClassEx, addr wc	; enregistre la window class définie au-dessus

    invoke CreateWindowEx, WS_EX_CLIENTEDGE,ADDR ClassName, \ 
                        ADDR AppName, WS_OVERLAPPEDWINDOW + WS_HSCROLL + WS_VSCROLL,\ 
                        CW_USEDEFAULT, CW_USEDEFAULT,\ 
                        largeur,hauteur,NULL,NULL, hInst,NULL 
    
    mov hwnd, eax ; eax=valeur de retour de CreateWindowEx, copiée dans hwnd 
    
	invoke ShowWindow, hwnd, SW_SHOWNORMAL ; handle de la fenêtre
										   ; mode d'affichage de la fenêtre
    
    messages:
        invoke GetMessage, ADDR msg, NULL, 0, 0 
        cmp eax, 0
        jle fin_boucle 
        invoke TranslateMessage, ADDR msg 
        invoke DispatchMessage, ADDR msg 
    jmp messages
    fin_boucle:
    mov     eax, msg.wParam 
    ret 
WinMain endp

RotationX proc _x:DWORD, _y:DWORD, _z:DWORD
	; Rotation selon X
	fild _y
	mov ecx, rotX
	fmul cosinus[ecx * REAL8] ; y * cos(rotX)
	fistp y2 ; y' = y * cos(rotX)
	fild _z
	mov ecx, rotX
	fmul sinus[ecx * REAL8] ; z * sin(rotX)
	fstp flottant
	fild y2
	fsub flottant
	fistp y2 ; y' = y * cos(rotX) - z * sin(rotX)
	
	fild _y
	mov ecx, rotX
	fmul sinus[ecx * REAL8] ; y * sin(rotX)
	fistp z2 ; z' = y * sin(rotX)
	fild _z
	mov ecx, rotX
	fmul cosinus[ecx * REAL8] ; z * cos(rotX)
	fstp flottant
	fild z2
	fadd flottant
	fistp z2 ; z' = y * sin(rotX) + z * cos(rotX)
	
	
	mov eax, y2
	mov ebx, z2
	ret
RotationX endp

RotationY proc _x:DWORD, _y:DWORD, _z:DWORD
	; Rotation selon Y
	fild _z
	mov ecx, rotY
	fmul sinus[ecx * REAL8] ; z * sin(rotY)
	fistp x2 ; x' = z * sin(rotY)
	fild _x
	mov ecx, rotY
	fmul cosinus[ecx * REAL8] ; x * cos(rotY)
	fstp flottant
	fild x2
	fadd flottant
	fistp x2 ; x' = z * sin(rotX) + x * cos(rotY)
	
	fild _z
	mov ecx, rotY
	fmul cosinus[ecx * REAL8] ; z * cos(rotY)
	fistp z2 ; z' = z * cos(rotY)
	fild _x
	mov ecx, rotY
	fmul sinus[ecx * REAL8] ; x * sin(rotY)
	fstp flottant
	fild z2
	fsub flottant
	fistp z2 ; z' = z * cos(rotY) - x * sin(rotY)
	
	
	mov eax, x2
	mov ebx, z2
	ret
RotationY endp

RotationZ proc _x:DWORD, _y:DWORD, _z:DWORD
	; Rotation selon Z
	fild _x
	mov ecx, rotZ
	fmul cosinus[ecx * REAL8] ; x * cos(rotZ)
	fistp x2 ; x' = x * cos(rotZ)
	fild _y
	mov ecx, rotZ
	fmul sinus[ecx * REAL8] ; y * sin(rotZ)
	fstp flottant
	fild x2
	fsub flottant
	fistp x2 ; x' = x * cos(rotZ) - y * sin(rotZ)
	
	fild _x
	mov ecx, rotZ
	fmul sinus[ecx * REAL8] ; x * sin(rotZ)
	fistp y2 ; y' = x * sin(rotZ)
	fild _y
	mov ecx, rotZ
	fmul cosinus[ecx * REAL8] ; y * cos(rotZ)
	fstp flottant
	fild y2
	fadd flottant
	fistp y2 ; y' = x * sin(rotZ) + y * cos(rotZ)
	
	
	mov eax, x2
	mov ebx, y2
	ret
RotationZ endp

Projection proc _x:DWORD, _y:DWORD, _z:DWORD
	invoke RotationX, _x, _y, _z
	mov _y, eax
	mov _z, ebx
	
	invoke RotationY, _x, _y, _z
	mov _x, eax
	mov _z, ebx
	
	invoke RotationZ, _x, _y, _z
	mov _x, eax
	mov _y, ebx

	fild _x
	fmul distFocale ; df * X
	mov ebx, _z
	add ebx, offZ
	mov _x, ebx ; Z + offZ
	fidiv _x ; (df * X) / (Z + offZ)
	fiadd offX ; (df * X) / (Z + offZ) + offX
	fistp _x
	fstp x
	
	fild _y
	fmul distFocale ; df * Y
	mov ebx, _z
	add ebx, offZ
	mov _y, ebx ; Z + offZ
	fidiv _y ; (df * Y) / (Z + offZ)
	fiadd offY ; (df * Y) / (Z + offZ) + offY
	fistp _y
	fstp y
	
	mov eax, _x
	mov ebx, _y
	
	ret
Projection endp

ProjectionMove proc _x:DWORD, _y:DWORD, _z:DWORD
	invoke Projection, _x, _y, _z
	invoke MoveToEx, hdc, eax, ebx, NULL
	
	ret
ProjectionMove endp

ProjectionDraw proc _x:DWORD, _y:DWORD, _z:DWORD
	invoke Projection, _x, _y, _z
	mov _x, eax
	mov _y, ebx
	invoke LineTo, hdc, eax, ebx
	invoke MoveToEx, hdc, _x, _y, NULL ; LineTo change les valeurs de eax et ebx
	
	ret
ProjectionDraw endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    cmp uMsg, WM_DESTROY	; demande de fermeture de la fenêtre (clic sur croix rouge)
    je destroy
    cmp uMsg, WM_PAINT	; message WM_PAINT envoyé à chaque rafraîchissement de la fenêtre
    je paint
    cmp uMsg, WM_KEYDOWN ; appui sur une touche
    je keyDown
    invoke DefWindowProc, hWnd, uMsg, wParam, lParam ; si aucun des messages précédents
    ret
    
    destroy:
    	invoke PostQuitMessage,NULL
    	
    jmp fin_messages

    paint:
    	invoke BeginPaint, hWnd, ADDR ps	; lance le dessin de la fenêtre
		mov hdc, eax	; BeginPaint retourne le handle du contexte où on dessine
		
		;;;;;; Cube
		;;; Face 0
		invoke ProjectionMove, -100, -100, -100 ; 0
		invoke ProjectionDraw, 100, -100, -100 ; 1
		invoke ProjectionDraw, 100, 100, -100 ; 2
		invoke ProjectionDraw, -100, 100, -100 ; 3
		
		;;; Face 1
		invoke ProjectionMove, 100, -100, -100 ; 1
		invoke ProjectionDraw, 100, -100, 100 ; 4
		invoke ProjectionDraw, 100, 100, 100 ; 7
		invoke ProjectionDraw, 100, 100, -100 ; 2
		
		;;; Face 2
		invoke ProjectionMove, 100, -100, 100 ; 4
		invoke ProjectionDraw, -100, -100, 100 ; 5
		invoke ProjectionDraw, -100, 100, 100 ; 6
		invoke ProjectionDraw, 100, 100, 100 ; 7
		
		;;; Face 3
		invoke ProjectionMove, -100, -100, 100 ; 5
		invoke ProjectionDraw, -100, -100, -100 ; 0
		invoke ProjectionDraw, -100, 100, -100 ; 3
		invoke ProjectionDraw, -100, 100, 100 ; 6
		
		;;; Face 4
		invoke ProjectionMove, -100, -100, 100 ; 5
		invoke ProjectionDraw, 100, -100, 100 ; 4
		invoke ProjectionDraw, 100, -100, -100 ; 1
		invoke ProjectionDraw, -100, -100, -100 ; 0
		
		;;; Face 5
		invoke ProjectionMove, -100, 100, -100 ; 3
		invoke ProjectionDraw, 100, 100, -100 ; 2
		invoke ProjectionDraw, 100, 100, 100 ; 7
		invoke ProjectionDraw, -100, 100, 100 ; 6
		
		;;;;;; Tétraèdre
;		;;; Face 0
;		invoke ProjectionMove, -100, 100, 100 ; 0
;		invoke ProjectionDraw, 100, 100, 100 ; 1
;		invoke ProjectionDraw, 0, -100, 0 ; 2
;		invoke ProjectionDraw, -100, 100, 100 ; 0
;		
;		;;; Face 1
;		invoke ProjectionMove, 100, 100, 100 ; 1
;		invoke ProjectionDraw, 0, 100, -100 ; 3
;		invoke ProjectionDraw, 0, -100, 0 ; 2
;		invoke ProjectionDraw, 100, 100, 100 ; 1
;		
;		;;; Face 2
;		invoke ProjectionMove, 0, 100, -100 ; 3
;		invoke ProjectionDraw, -100, 100, 100 ; 0
;		invoke ProjectionDraw, 0, -100, 0 ; 2
;		invoke ProjectionDraw, 0, 100, -100 ; 3
;		
;		;;; Face 3
;		invoke ProjectionMove, -100, 100, 100 ; 0
;		invoke ProjectionDraw, 0, 100, -100 ; 3
;		invoke ProjectionDraw, 100, 100, 100 ; 1
;		invoke ProjectionDraw, -100, 100, 100 ; 0
		
        invoke EndPaint, hWnd, ADDR ps ; fin du dessin de la fenêtre
        jmp fin_messages
        
    keyDown:
		mov eax, wParam ; Touche pressée
    	cmp eax, VK_OEM_PLUS
    	je keyZoom
    	cmp eax, VK_ADD
    	je keyZoom
    	cmp eax, VK_OEM_MINUS
    	je keyDezoom
    	cmp eax, VK_SUBTRACT
    	je keyDezoom
    	cmp eax, VK_UP
    	je keyUp
    	cmp eax, VK_DOWN
    	je _keyDown
    	cmp eax, VK_LEFT
    	je keyLeft
    	cmp eax, VK_RIGHT
    	je keyRight
    	cmp eax, VK_X
    	je rotateX
    	cmp eax, VK_Y
    	je rotateY
    	cmp eax, VK_Z
    	je rotateZ
    	cmp eax, VK_Q
    	je keyQuit
    	cmp eax, VK_ESCAPE
    	je keyQuit
    	
    	jmp fin_messages
    	
    keyDezoom:
    	add offZ, 30
    	jmp repaint
    	
    keyZoom:
    	sub offZ, 30
    	jmp repaint
    	
    keyUp:
    	sub offY, 30
    	jmp repaint
    	
    _keyDown:
    	add offY, 30
    	jmp repaint
    	
    keyLeft:
    	sub offX, 30
    	jmp repaint
    	
    keyRight:
    	add offX, 30
    	jmp repaint
    	
    keyQuit:
    	jmp destroy
    	
    rotateX:
    	add rotX, 5
    	cmp rotX, 360
    	jae resetRotX
    	jmp repaint
    rotateY:
    	add rotY, 5
    	cmp rotY, 360
    	jae resetRotY
    	jmp repaint
    rotateZ:
    	add rotZ, 5
    	cmp rotZ, 360
    	jae resetRotZ
    	jmp repaint
    	
    resetRotX:
    	mov rotX, 0
    	jmp repaint
    resetRotY:
    	mov rotY, 0
    	jmp repaint
    resetRotZ:
    	mov rotZ, 0
    	jmp repaint
    	
    repaint:
    	mov eax, RDW_ERASE
    	or eax, RDW_INVALIDATE
    	invoke RedrawWindow, hWnd, NULL, NULL, eax
        
    fin_messages:
    xor    eax,eax 
    ret 
WndProc endp 
push 0
call ExitProcess      	
end start