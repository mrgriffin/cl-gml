(0,-1,0) (1,1,0) makeVEFS          % e0
	dup (-1,1,0) makeEVone     % e0 e1
	1 index 1 index makeEF     % e0 e1 e2             | f0
	dup (0,0,1) makeEVone      % e0 e1 e2 e3
	3 index 1 index makeEF     % e0 e1 e2 e3 e4       | f1
	3 index 1 index makeEF     % e0 e1 e2 e3 e4 e5    | f2
	3 index 1 index makeEF     % e0 e1 e2 e3 e4 e5 e2 | f3
pop pop pop pop pop pop
