program solve_chess;

label 
    NextFirstWinnerMove, NextEnemyMoveCheck;

type
    TCoordinate = record
        x: Integer;
        y: Integer;
    end;

type 
    TMoves = array[1..1000] of array[1..3] of string;

type
    TChessBoard = array[1..8, 1..8] of string;
    TPossibleMoves = array[1..10000] of TCoordinate; // здесь хранятся возможные координаты для перемещения фигуры

function IsKingInCheck(chessBoard: TChessBoard; king: string): boolean; forward;
function getPossibleMoves(chessBoard: TChessBoard; figure: string; i, j: integer): TPossibleMoves; forward;    
    
var
    possibleMoves1, possibleMoves2, possibleMoves3: TPossibleMoves;
    chessBoard: TChessBoard;
    ConfigFile: TextFile;
    line, playerToWin, figure: string;
    i, j, i1, j1, i2, j2, m1, m2, m3, u1, h1, u2, h2, q: integer; // i j - для перебора победителя, u h - для перебора противника 
    fileName, figureToMove1, figureToMove2, figureToMove3, removedFigure1, removedFigure2, removedFigure3, move1, move2, move3: string;
    mateIsPossible, figureFound, isLastEnemyFigure: boolean;
    moves, globalMoves: TMoves; // массив движений для мата 

procedure clearMoves(var moves: TMoves);
var
    i, j: integer;
begin
    for i := 1 to 1000 do
    begin
        for j := 1 to 3 do
        begin
            moves[i][j] := '0'; // устанавливаем базовое значение '0'
        end;
    end;
end;

procedure PrintChessBoard(board: TChessBoard);
var
  i, j: integer;
begin
    writeln('    a  b  c  d  e  f  g  h');  // заголовок для колонок с отступами
    writeln('  +------------------------+');
    for i := 1 to 8 do  // проходим по строкам сверху вниз
    begin
        write(9 - i, ' |');  // печатаем номер строки с выравниванием
        for j := 1 to 8 do
        begin
            if board[i, j] = '' then
            begin
                write(' --');  // пустая клетка обозначена как "--"
            end
            else begin
                write(' ', board[i, j]); 
            end;
        end;
    writeln(' | ', 9 - i);  // завершаем строку с номером строки справа
    end;
    writeln('  +------------------------+');
    writeln('    a  b  c  d  e  f  g  h');  // повторяем заголовок для колонок с отступами
end;

procedure AddToFirstEmpty(var arr: TPossibleMoves; i, j: integer);
var
    q: integer;
begin  
    for q := 1 to length(arr) do
    begin
        if (arr[q].x = 0) then // проверяем, не хранится ли коордианата в переменной
        begin
            arr[q].x := j; // добавляем новые значения
            arr[q].y := i;
            exit;              
        end;
    end;
end;

procedure AddMoves(var moves: TMoves; move1, move2, move3: string);
var
  q: integer;
begin  
    for q := 1 to 1000 do
    begin
        if (moves[q][1] = '0') then // проверяем, не хранится ли значение в переменной
        begin
            moves[q][1] := move1; // добавляем новые значения
            moves[q][2] := move2;
            moves[q][3] := move3;
            exit;              
        end;
    end;
end;

procedure AddMovesToGlobalMoves(var globalMoves: Tmoves; moves: TMoves);
var
    q, i, qw: integer;
begin
    for q := 1 to 1000 do
    begin
        if (globalMoves[q][1] = '0') then // проверяем, не хранится ли значение в переменной
        begin
            qw := q;
            for i := 1 to 1000 do
            begin
                if (moves[i][1] <> '0') then
                begin
                    globalMoves[qw][1] := moves[i][1];
                    globalMoves[qw][2] := moves[i][2];
                    globalMoves[qw][3] := moves[i][3];
                end;
                qw += 1;
            end;
            exit;
        end;
    end;
end;

function uniteTwoArrays(arr1, arr2: TPossibleMoves) : TPossibleMoves;
var
    i: integer;
begin
    for i := 1 to 10000 do 
    begin
        if (arr2[i].x = 0) then
        begin
            break;
        end;
        AddToFirstEmpty(arr1, arr2[i].y, arr2[i].x);
    end;
    uniteTwoArrays := arr1;
    exit;
end;

procedure CheckAndAddKingMove(chessBoard: TChessBoard; var possibleMoves: TPossibleMoves; figure: string; i, j, deltaX, deltaY: integer);
begin
  // Проверяем, что новая позиция находится в пределах доски
  if (i + deltaX >= 1) and (i + deltaX <= 8) and (j + deltaY >= 1) and (j + deltaY <= 8) then 
  begin
    // Проверяем, что клетка пуста или содержит фигуру противника
    if (chessBoard[i + deltaX, j + deltaY] = '--') or (chessBoard[i + deltaX, j + deltaY][2] <> figure[2]) then
    begin
      // Изменяем доску для проверки хода
      chessBoard[i, j] := '--';
      chessBoard[i + deltaX, j + deltaY] := figure;
      // Проверяем, находится ли король под шахом после хода
      if (IsKingInCheck(chessBoard, figure) = false) then
      begin
        AddToFirstEmpty(possibleMoves, i + deltaX, j + deltaY);
      end;
    end;
  end;
end;

function getPossibleMoves(chessBoard: TChessBoard; figure: string; i, j: integer): TPossibleMoves;
var 
    possibleMoves, psM1, psMforKing, psMforEnemyKing: TPossibleMoves;
    q, h, m, ki1, kj1: integer;
    removedKing, removedByKingFigure: string;
    chessBoardForKing: TChessBoard;
begin

    for q := 1 to 10000 do // зануляем possibleMoves
    begin
        if (possibleMoves[q].x = 0) then
        begin
            break;
        end;
        possibleMoves[q].x := 0;
        possibleMoves[q].y := 0;
    end;

    for q := 1 to 10000 do // зануляем psMforKing
    begin
        if (psMforKing[q].x = 0) then
        begin
            break;
        end;
        psMforKing[q].x := 0;
        psMforKing[q].y := 0;
    end;
    
// ПЕШКА
    if (figure[1] = 'p') then // доступные движения для пешки
    begin
        if (figure[2] = 'w') then // движения белой пешки
        begin
            if (i = 1) then // дошла до края доски, вариант превращения в ферзя не рассматривается 
            begin
                possibleMoves[1].x := 0;
                possibleMoves[1].y := 0;
                getPossibleMoves := possibleMoves;
                exit;
            end;       
            if (i = 7) then // начальная позиция пешки может пойти на +1 +2 вперёд (на доске она стоит уже на 7 строке, поэтому i-1), если пустая клетка
            begin
                if (chessBoard[i-1, j] = '--') then
                begin
                    AddToFirstEmpty(possibleMoves, i-1, j); 
                end;
                if (chessBoard[i-2, j] = '--') then
                begin
                    AddToFirstEmpty(possibleMoves, i-2, j);
                end;
            end
            else begin // неначальная позиция пешки
                if (chessBoard[i-1, j] = '--') then
                begin
                    AddToFirstEmpty(possibleMoves, i-1, j); // может пойти на +1
                end;
            end;
            if (chessBoard[i-1, j+1][2] = 'b') then // если справа спереди стоит противник, то можно его съесть 
            begin
                AddToFirstEmpty(possibleMoves, i-1, j+1);
            end;
            if (chessBoard[i-1, j-1][2] = 'b') then // если слева спереди стоит противник, то можно его съесть 
            begin
                AddToFirstEmpty(possibleMoves, i-1, j-1);
            end;
        end
        else begin // движения чёрной пешки
            if (i = 8) then // дошла до края доски, вариант превращения в ферзя не рассматривается 
            begin
                possibleMoves[1].x := 0;
                possibleMoves[1].y := 0;
                getPossibleMoves := possibleMoves;
                exit;
            end;
            if (i = 2) then // начальная позиция пешки может пойти на +1 +2 вперёд (на доске она стоит уже на 2 строке, поэтому i+1), если пустая клетка
            begin
                if (chessBoard[i+1, j] = '--') then
                begin
                    AddToFirstEmpty(possibleMoves, i+1, j); 
                end;
                if (chessBoard[i+2, j] = '--') then
                begin
                    AddToFirstEmpty(possibleMoves, i+2, j);
                end;
            end
            else begin // неначальная позиция пешки
                if (chessBoard[i+1, j] = '--') then
                begin
                    AddToFirstEmpty(possibleMoves, i+1, j); // может пойти на +1
                end;
            end;
            if (chessBoard[i+1, j+1][2] = 'w') then // если справа спереди стоит противник, то можно его съесть 
            begin
                AddToFirstEmpty(possibleMoves, i+1, j+1);
            end;
            if (chessBoard[i+1, j-1][2] = 'w') then // если слева спереди стоит противник, то можно его съесть 
            begin
                AddToFirstEmpty(possibleMoves, i+1, j-1);
            end;
        end;
    end;

// ЛАДЬЯ
    if (figure[1] = 'R') then // доступные движения для ладьи
    begin // одинаково для белых и чёрных
        for q := i+1 to 8 do begin // вертикальный ход вниз
            if (chessBoard[q, j] <> '--') then // если встретилась непустая клетка на пути
            begin
                if (chessBoard[q,j][2] <> figure[2]) then // если встретилась фигура противника
                begin
                    AddToFirstEmpty(possibleMoves, q, j); // можно съесть
                    break;
                end
                else begin // иначе нельзя съесть, фигура своего цвета
                    break;
                end;
            end;
            AddToFirstEmpty(possibleMoves, q, j);
        end;

        for q := i-1 downto 1 do begin // вертикальный ход вверх
            if (chessBoard[q, j] <> '--') then // если встретилась непустая клетка на пути
            begin
                if (chessBoard[q,j][2] <> figure[2]) then // если встретилась фигура противника
                begin
                    AddToFirstEmpty(possibleMoves, q, j); // можно съесть
                    break;
                end
                else begin // иначе нельзя съесть, фигура своего цвета
                    break;
                end;
            end;
            AddToFirstEmpty(possibleMoves, q, j);
        end;

        for q := j+1 to 8 do begin // горизонтальный ход вправо
            if (chessBoard[i, q] <> '--') then // если встретилась непустая клетка на пути
            begin
                if (chessBoard[i, q][2] <> figure[2]) then // если встретилась фигура противника
                begin
                    AddToFirstEmpty(possibleMoves, i, q); // можно съесть
                    break;
                end
                else begin // иначе нельзя съесть, фигура своего цвета
                    break;
                end;
            end;
            AddToFirstEmpty(possibleMoves, i, q);
        end;

        for q := j-1 downto 1 do begin // горизонтальный ход влево
            if (chessBoard[i, q] <> '--') then // если встретилась непустая клетка на пути
            begin
                if (chessBoard[i, q][2] <> figure[2]) then // если встретилась фигура противника
                begin
                    AddToFirstEmpty(possibleMoves, i, q); // можно съесть
                    break;
                end
                else begin // иначе нельзя съесть, фигура своего цвета
                    break;
                end;
            end;
            AddToFirstEmpty(possibleMoves, i, q);
        end;
    end;

// СЛОН
    if (figure[1] = 'B') then
    begin // одинаково для чёреных и белых
        h := j; 
        for q := i+1 to 8 do begin // вверх вправо
            h += 1;
            if (h > 8) then // если вышли за пределы доски
            begin
                break;
            end;
            if (chessBoard[q, h] = '--') then // клетка пустая
            begin
                AddToFirstEmpty(possibleMoves, q, h);
            end
            else begin // клетка содержит фигуры
                if (chessBoard[q, h][2] <> figure[2]) then // в клетке фигура противника
                begin
                    AddToFirstEmpty(possibleMoves, q, h);
                    break;
                end
                else begin
                    break;
                end;
            end;
        end;

        h := j;
        for q := i-1 downto 1 do begin // вниз вправо
            h += 1;
            if (h > 8) then 
            begin
                break;
            end;
            if (chessBoard[q, h] = '--') then // клетка пустая
            begin
                AddToFirstEmpty(possibleMoves, q, h);
            end
            else begin // клетка содержит фигуры
                if (chessBoard[q, h][2] <> figure[2]) then // в клетке фигура противника
                begin
                    AddToFirstEmpty(possibleMoves, q, h);
                    break;
                end
                else begin
                    break;
                end;
            end;
        end;

        h := j; 
        for q := i+1 to 8 do begin // вверх влево
            h -= 1;
            if (h < 1) then // если вышли за пределы доски
            begin
                break;
            end;
            if (chessBoard[q, h] = '--') then // клетка пустая
            begin
                AddToFirstEmpty(possibleMoves, q, h);
            end
            else begin // клетка содержит фигуры
                if (chessBoard[q, h][2] <> figure[2]) then // в клетке фигура противника
                begin
                    AddToFirstEmpty(possibleMoves, q, h);
                    break;
                end
                else begin
                    break;
                end;
            end;
        end;

        h := j;
        for q := i-1 downto 1 do begin // вниз влево
            h -= 1;
            if (h < 1) then 
            begin
                break;
            end;
            if (chessBoard[q, h] = '--') then // клетка пустая
            begin
                AddToFirstEmpty(possibleMoves, q, h);
            end
            else begin // клетка содержит фигуры
                if (chessBoard[q, h][2] <> figure[2]) then // в клетке фигура противника
                begin
                    AddToFirstEmpty(possibleMoves, q, h);
                    break;
                end
                else begin
                    break;
                end;
            end;
        end;
    end;

// ФЕРЗЬ
    if (figure[1] = 'Q') then
    begin
        chessBoard[i, j][1] := 'B'; // движения ферзя - это движения ладьи + слона
        figure[1] := 'B';
        psM1 := getPossibleMoves(chessBoard, figure, i, j);
        chessBoard[i, j][1] := 'R';
        figure[1] := 'R';
        possibleMoves := getPossibleMoves(chessBoard, figure, i, j);
        possibleMoves := uniteTwoArrays(psM1, possibleMoves); 
        chessBoard[i, j][1] := 'Q';
        figure[1] := 'Q';
    end;

// КОНЬ 
    if (figure[1] = 'N') then // | + 2 - 1 | + 2 + 1 | - 2 - 1 | - 2 + 1 | - 1 + 2 | + 1 + 2 | - 1 - 2 | + 1 - 2 | - возможные шаги коня
    begin
        if (i+2 <= 8) and (j-1 >= 1) then begin // + 2 - 1
            if (chessBoard[i+2, j-1] = '--') or (chessBoard[i+2, j-1][2] <> figure[2]) then
            begin
                AddToFirstEmpty(possibleMoves, i+2, j-1);
            end;
        end;

        if (i+2 <= 8) and (j+1 <= 8) then begin // + 2 + 1
            if (chessBoard[i+2, j+1] = '--') or (chessBoard[i+2, j+1][2] <> figure[2]) then
            begin
                AddToFirstEmpty(possibleMoves, i+2, j+1);
            end;
        end;

        if (i-2 >= 1) and (j-1 >= 1) then begin // - 2 - 1
            if (chessBoard[i-2, j-1] = '--') or (chessBoard[i-2, j-1][2] <> figure[2]) then
            begin
                AddToFirstEmpty(possibleMoves, i-2, j-1);
            end;
        end;

        if (i-2 >= 1) and (j+1 <= 8) then begin // - 2 + 1
            if (chessBoard[i-2, j+1] = '--') or (chessBoard[i-2, j+1][2] <> figure[2]) then
            begin
                AddToFirstEmpty(possibleMoves, i-2, j+1);
            end;
        end;

        if (i-1 >= 1) and (j+2 <= 8) then begin // - 1 + 2
            if (chessBoard[i-1, j+2] = '--') or (chessBoard[i-1, j+2][2] <> figure[2]) then
            begin
                AddToFirstEmpty(possibleMoves, i-1, j+2);
            end;
        end;

        if (i+1 <= 8) and (j+2 <= 8) then begin // + 1 + 2
            if (chessBoard[i+1, j+2] = '--') or (chessBoard[i+1, j+2][2] <> figure[2]) then
            begin
                AddToFirstEmpty(possibleMoves, i+1, j+2);
            end;
        end;

        if (i-1 >= 1) and (j-2 >= 1) then begin // - 1 - 2
            if (chessBoard[i-1, j-2] = '--') or (chessBoard[i-1, j-2][2] <> figure[2]) then
            begin
                AddToFirstEmpty(possibleMoves, i-1, j-2);
            end;
        end;

        if (i+1 <= 8) and (j-2 >= 1) then begin // + 1 - 2
            if (chessBoard[i+1, j-2] = '--') or (chessBoard[i+1, j-2][2] <> figure[2]) then
            begin
                AddToFirstEmpty(possibleMoves, i+1, j-2);
            end;
        end;
    end;

// КОРОЛЬ
    if (figure[1] = 'K') then // не учитывается рокировка
    begin
        CheckAndAddKingMove(chessBoard, possibleMoves, figure, i, j, 1, 1);  // +1, +1
        CheckAndAddKingMove(chessBoard, possibleMoves, figure, i, j, 1, -1); // +1, -1
        CheckAndAddKingMove(chessBoard, possibleMoves, figure, i, j, -1, 1); // -1, +1
        CheckAndAddKingMove(chessBoard, possibleMoves, figure, i, j, -1, -1);// -1, -1
        CheckAndAddKingMove(chessBoard, possibleMoves, figure, i, j, 1, 0);  // +1, 0
        CheckAndAddKingMove(chessBoard, possibleMoves, figure, i, j, -1, 0); // -1, 0
        CheckAndAddKingMove(chessBoard, possibleMoves, figure, i, j, 0, 1);  // 0, +1
        CheckAndAddKingMove(chessBoard, possibleMoves, figure, i, j, 0, -1); // 0, -1
    end;

    if (figure[1] <> 'Q') then // координаты ферзя не надо реверсировать (??)
    begin
        for q := 1 to 10000 do // реверсируем координаты, чтобы правильно передавать их для поиска элемента в матрице, где сначала даётся y, потом x
        begin
            if (possibleMoves[q].x = 0) then
            begin
                break;
            end;
            h := possibleMoves[q].x;
            possibleMoves[q].x := possibleMoves[q].y;
            possibleMoves[q].y := h; 
        end;
    end;

    getPossibleMoves := possibleMoves;
end;

function IsKingInCheck(chessBoard: TChessBoard; king: string): boolean;
var
  i, j, m: integer;
  kingPosition: TCoordinate;
  opponentMoves: TPossibleMoves;
begin
  for i := 1 to 8 do // Находим координаты короля на доске
    for j := 1 to 8 do
      if (chessBoard[i, j] = king) then
      begin
        kingPosition.x := i;
        kingPosition.y := j;
        break;
      end;

  for i := 1 to 8 do // Проверяем все фигуры противника
    for j := 1 to 8 do
      if (chessBoard[i, j] <> '--') and (chessBoard[i, j][1] <> 'K') and (chessBoard[i, j][2] <> king[2]) then // Не рассматриваются движения вражеского короля
      begin
        opponentMoves := getPossibleMoves(chessBoard, chessBoard[i, j], i, j);
        for m := 1 to 10000 do
        begin
          if (opponentMoves[m].x = 0) then
            break;
          if (opponentMoves[m].x = kingPosition.x) and (opponentMoves[m].y = kingPosition.y) then // Если среди возможных ходов противника есть координаты короля, то это шах
          begin
            IsKingInCheck := true;
            exit;
          end;
        end;
      end;
      
  for i := kingPosition.x - 1 to kingPosition.x + 1 do // Проверка, что в области +-1 клетка стоит другой король
    for j := kingPosition.y - 1 to kingPosition.y + 1 do
    begin
      if (i >= 1) and (i <= 8) and (j >= 1) and (j <= 8) and ((i <> kingPosition.x) or (j <> kingPosition.y)) and (chessBoard[i, j][1] = 'K') then
        begin
          IsKingInCheck := true;
          exit;
        end;
    end;
  IsKingInCheck := false; // Если не найдено ни одного удара по королю, возвращаем false
end;

function itIsMate(chessBoard: TChessBoard; playerToWin: string): boolean; // проверить все возможные ходы победителя, 
var                                             // где он ест короля следующим ходом, независимо от текущего хода проигравшего
    figureToMove1, removedFigure1: string;
    i, j, u, h, ku, kh, ku0, kh0, m1, m2: integer;
    possibleMoves1, possibleMoves2: TPossibleMoves;
    thisIsMate: boolean;
begin
    for u := 1 to 8 do 
    begin
        for h := 1 to 8 do begin
            if (chessBoard[u, h][1] = 'K') and (chessBoard[u, h][2] <> playerToWin[1]) then // нашли координаты короля, которому ставится мат
            begin
                ku := u;
                kh := h;
                ku0 := u;
                kh0 := h;
            end;
        end;
    end;

    for u := 1 to 8 do 
    begin
        for h := 1 to 8 do
        begin
            if (chessBoard[u, h][2] <> playerToWin[1]) then // перебираем фигуры проигравшего, их движения
            begin
                figureToMove1 := chessBoard[u, h]; 
                possibleMoves1 := getPossibleMoves(chessBoard, chessBoard[u, h], u, h);
                chessBoard[u, h] := '--';
                for m1 := 1 to 10000 do  
                begin
                    if (possibleMoves1[m1].x = 0) then
                    begin
                        break;
                    end;
                    if (figureToMove1[1] = 'K') then begin // если рассматриваются движения короля
                        ku := possibleMoves1[m1].x; // обновляем координаты короля
                        kh := possibleMoves1[m1].y;
                    end;
                    removedFigure1 := chessBoard[possibleMoves1[m1].x, possibleMoves1[m1].y]; 
                    chessBoard[possibleMoves1[m1].x, possibleMoves1[m1].y] := figureToMove1;

                    thisIsMate := false; // пока мат не доказан на текущий ход проигравшего
                    for i := 1 to 8 do // перебираем фигуры и ходы победителя, чтобы выяснить, может ли он съесть фигуру по координатам короля
                    begin               // если нет, то это не мат, у проигравшего есть выход
                        for j := 1 to 8 do 
                        begin
                            if (chessBoard[i, j][2] = playerToWin[1]) then 
                            begin
                                possibleMoves2 := getPossibleMoves(chessBoard, chessBoard[i, j], i, j);
                                for m2 := 1 to 10000 do // перебираем ходы фигур победителя 
                                begin
                                    if (possibleMoves2[m2].x = 0) then
                                    begin
                                        break;
                                    end;
                                    if (possibleMoves2[m2].x = ku) and (possibleMoves2[m2].y = kh) then // победитель может съесть короля в этом раскладе
                                    begin
                                        thisIsMate := true;
                                        break;
                                    end;
                                end;
                                if (thisIsMate = true) then
                                begin
                                    break;
                                end;
                            end;
                        end;
                        if (thisIsMate = true) then
                        begin
                            break;
                        end;
                    end;
                    chessBoard[possibleMoves1[m1].x, possibleMoves1[m1].y] := removedFigure1;
                    if (thisIsMate = false) then // закончился перебор всех ходов победителя на текущий ход проигравшего, мат не был поставлен
                    begin                               // значит, есть ход проигравшего, который приводит к тому, что мат нельзя поставить
                        chessBoard[u, h] := figureToMove1;
                        chessBoard[possibleMoves1[m1].x, possibleMoves1[m1].y] := removedFigure1;
                        itIsMate := false;
                        exit;
                    end;

                end;
                chessBoard[u, h] := figureToMove1;
                ku := ku0; // восстанавливаем базовые координаты короля после перебора возможных ходов фигуры
                kh := kh0; // на тот случай, если перебирались ходы короля и его координаты менялись 
            end;
        end;
    end; 

    itIsMate := true; // так и не было найдено хода проигравшего, который привёл бы к тому, что победитель не может съесть короля
    exit;
end;

function getEnemyColor(color: string): string;
begin
    if (color = 'black') then begin
        getEnemyColor := 'white';
        exit;
    end;
    if (color = 'white') then begin
        getEnemyColor := 'black';
        exit;
    end;
    getEnemyColor := 'unknown color';
end;

begin
    fileName := ParamStr(1);
    playerToWin := ParamStr(2);
    assign(ConfigFile, fileName);
    reset(ConfigFile);
    
    i := 1;
    while not eof(ConfigFile) and (i <= 8) do
    begin
        readln(ConfigFile, line);
        for j := 1 to 8 do
        begin
            if Pos(' ', line) > 0 then
            begin
                chessBoard[i, j] := Copy(line, 1, Pos(' ', line) - 1);  // извлекаем первый элемент до пробела
                Delete(line, 1, Pos(' ', line));  // удаляем извлеченный элемент и пробел
            end
            else begin
                chessBoard[i, j] := line;  // усли пробелов больше нет, присваиваем оставшуюся строку
                line := '';  // очищаем line, чтобы завершить цикл
            end;
        end;
    i := i + 1;
    end;
    close(ConfigFile);
    move1 := '__ ____'; 
    move2 := '__ ____'; 
    move3 := '__ ____'; 
    clearMoves(globalMoves); // устанавливаем чистые глобальные движения

    //(i, j) - координаты движений фигур цвета-победителя, (u, h) - цвета-проигравшего
    for i1 := 1 to 8 do // перебираем первый ход победителя
    begin
        for j1 := 1 to 8 do
        begin
            if (chessBoard[i1, j1][2] = playerToWin[1]) then // перебираем фигуры нужного цвета
            begin
                clearMoves(moves); // очищаем движения на текущую фигуру
                figureToMove1 := chessBoard[i1, j1]; // запоминаем фигуру
                move1[1] := figureToMove1[1]; // запоминаем, какой фигуры движение
                move1[2] := figureToMove1[2];
                move1[5] := Chr(Ord('0') + 9 - i1); // запоминаем координаты фигуры
                move1[4] := Chr(Ord('`') + j1); 
                possibleMoves1 := getPossibleMoves(chessBoard, chessBoard[i1, j1], i1, j1); // получаем возможные шаги фигуры и перебираем их
                chessBoard[i1, j1] := '--'; // перебираем возможные шаги фигуры, фигура уходит из своей клетки
                for m1 := 1 to 10000 do 
                begin
                    if (possibleMoves1[m1].x = 0) then 
                    begin
                        break;
                    end;
                    if ((possibleMoves1[m1].x > 8) or (possibleMoves1[m1].x < 1) or (possibleMoves1[m1].y > 8) or (possibleMoves1[m1].y < 1)) then begin
                        continue;
                    end;
                    move1[7] := Chr(Ord('0') + 9 - possibleMoves1[m1].x);
                    move1[6] := Chr(Ord('`') + possibleMoves1[m1].y);
                    removedFigure1 := chessBoard[possibleMoves1[m1].x, possibleMoves1[m1].y]; // запоминаем фигуру, на место которая сейчас встанет рассматриваемая фигура
                    chessBoard[possibleMoves1[m1].x, possibleMoves1[m1].y] := figureToMove1; // одно из возможных движений фигуры, записываем в доску
                    // на этом моменте мы рассматриваем шахматную доску, где цвет-победитель сделал какой-то первый ход

                    if (itIsMate(chessBoard, playerToWin)) then begin // мат в один ход
                        writeln(move1);
                        writeln('---');
                        goto NextFirstWinnerMove;
                    end;

                    for u1 := 1 to 8 do // перебираем фигуры противника
                    begin
                        for h1 := 1 to 8 do
                        begin
                            if ((chessBoard[u1, h1][2] <> playerToWin[1]) and (chessBoard[u1, h1][2] <> '-')) then
                            begin
                                figureToMove2 := chessBoard[u1, h1];
                                move2[1] := figureToMove2[1];
                                move2[2] := figureToMove2[2];
                                move2[5] := Chr(Ord('0') + 9 - u1);
                                move2[4] := Chr(Ord('`') + h1);
                                possibleMoves2 := getPossibleMoves(chessBoard, chessBoard[u1, h1], u1, h1);
                                chessBoard[u1, h1] := '--';
                                for m2 := 1 to 10000 do // перебираем ходы противника на текущую фигуру
                                begin 
                                    if (possibleMoves2[m2].x = 0) then
                                    begin
                                        break;
                                    end;
                                    if ((possibleMoves2[m2].x > 8) or (possibleMoves2[m2].x < 1) or (possibleMoves2[m2].y > 8) or (possibleMoves2[m2].y < 1)) then begin
                                        continue;
                                    end;
                                    move2[7] := Chr(Ord('0') + 9 - possibleMoves2[m2].x);
                                    move2[6] := Chr(Ord('`') + possibleMoves2[m2].y);
                                    removedFigure2 := chessBoard[possibleMoves2[m2].x, possibleMoves2[m2].y];
                                    chessBoard[possibleMoves2[m2].x, possibleMoves2[m2].y] := figureToMove2;
                                    mateIsPossible := false; // установим мат на false перед перебором ответных ходов победителя, где хоть один ставящий мат ход
                                                            // установит mateIsPossible на true для этого хода противника
                                    for i2 := 1 to 8 do // третий ход победителя, должен ставить мат каким-то (хотя бы 1) ходом на любой шаг противника
                                    begin              
                                        for j2 := 1 to 8 do
                                        begin
                                            if (chessBoard[i2, j2][2] = playerToWin[1]) then
                                            begin
                                                figureToMove3 := chessBoard[i2, j2];
                                                move3[1] := figureToMove3[1];
                                                move3[2] := figureToMove3[2];
                                                move3[5] := Chr(Ord('0') + 9 - i2);
                                                move3[4] := Chr(Ord('`') + j2);
                                                possibleMoves3 := getPossibleMoves(chessBoard, chessBoard[i2, j2], i2, j2);
                                                chessBoard[i2, j2] := '--';
                                                for m3 := 1 to 10000 do 
                                                begin
                                                    if (possibleMoves3[m3].x = 0) then
                                                    begin
                                                        break;
                                                    end;
                                                    if ((possibleMoves3[m3].x > 8) or (possibleMoves3[m3].x < 1) or (possibleMoves3[m3].y > 8) or (possibleMoves3[m3].y < 1)) then begin
                                                        continue;
                                                    end; // !! иногда случайно выдаёт условно y = 11455 (??)
                                                    removedFigure3 := chessBoard[possibleMoves3[m3].x, possibleMoves3[m3].y]; 
                                                    chessBoard[possibleMoves3[m3].x, possibleMoves3[m3].y] := figureToMove3;

                                                    if (itIsMate(chessBoard, playerToWin) = true) then // проверка на мат
                                                    begin                                   
                                                        mateIsPossible := true;   // возможно поставить мат на текущий ход противника                                                        
                                                        move3[7] := Chr(Ord('0') + 9 - possibleMoves3[m3].x);
                                                        move3[6] := Chr(Ord('`') + possibleMoves3[m3].y); 
                                                        chessBoard[possibleMoves3[m3].x, possibleMoves3[m3].y] := removedFigure3;
                                                        chessBoard[i2, j2] := figureToMove3;
                                                        AddMoves(moves, move1, move2, move3);
                                                        chessBoard[possibleMoves2[m2].x, possibleMoves2[m2].y] := removedFigure2;
                                                        
                                                        // проверка, последняя ли фигура противника перебирается
                                                        isLastEnemyFigure := true; // по умолчанию фигура последняя, но если найдём ещё одну дальше на доске, то false
                                                        for u2 := u1 to 8 do
                                                        begin
                                                            for h2 := ((h1 + 1) mod 8) to 8 do begin
                                                                if (h2 = 0) then begin // если уже конец строки доски, то перебираем следующую
                                                                    continue;
                                                                end;   
                                                                if (chessBoard[u2, h2][2] <> playerToWin[1]) and (chessBoard[u2, h2][2] <> '-') then
                                                                begin   // нашли ещё одну дальше, значит не последняя доступная фигура
                                                                    isLastEnemyFigure := false;
                                                                    break;
                                                                end;
                                                            end;
                                                            if (isLastEnemyFigure = false) then begin
                                                                break;
                                                            end;
                                                        end;
                                                        
                                                        if ((isLastEnemyFigure = true) and (possibleMoves2[m2+1].x = 0)) then // последний возможный ход противника
                                                        begin // соответсвенно на все ходы противника нашёлся мат
                                                            AddMovesToGlobalMoves(globalMoves, moves); // сохраняем ходы для вывода
                                                            clearMoves(moves);
                                                        end;

                                                        goto NextEnemyMoveCheck; // идём перебирать следующую первую фигуру
                                                    end;
                                                    chessBoard[possibleMoves3[m3].x, possibleMoves3[m3].y] := removedFigure3;
                                                end;
                                                chessBoard[possibleMoves3[m3].x, possibleMoves3[m3].y] := removedFigure3;
                                                chessBoard[i2, j2] := figureToMove3;
                                            end;
                                        end;
                                    end;

                                    // проверка на мат сразу после перебора последнего хода победителя 
                                    if (mateIsPossible = false) then // мат невозможен при таком ответном ходе противника, значит не гарантирован при таком первом ходе победителя
                                    begin
                                        clearMoves(moves); // очищаем записанные ранее ходы для этого первого хода, т.к. нашёлся ответ, защищающий противника от мата
                                        // восстановить состояние доски
                                        chessBoard[u1, h1] := figureToMove2;
                                        chessBoard[possibleMoves2[m2].x, possibleMoves2[m2].y] := removedFigure2;
                                        goto NextFirstWinnerMove; // идём перебирать следующую первую фигуру
                                    end;
                                    NextEnemyMoveCheck:

                                end;
                                chessBoard[u1, h1] := figureToMove2;
                            end;
                        end;
                        chessBoard[possibleMoves2[m2].x, possibleMoves2[m2].y] := removedFigure2;
                    end;
                    NextFirstWinnerMove:
                    chessBoard[possibleMoves1[m1].x, possibleMoves1[m1].y] := removedFigure1; // возвращаем съеденную фигуру, на место которой вставала рассматриваемая
                end;                                            
                chessBoard[i1, j1] := figureToMove1; // возвращаем фигуру в свою клетку, перебираем другую фигуру и её действия
            end;                                   // возвращаемся к рассмотрению других возможных ходов победителя
        end;
    end;

    for q := 1 to 1000 do // итоговая печать ходов
    begin
        if (globalMoves[q][1] = '0') then begin
            break;
        end;

        writeln(globalMoves[q][1]);
        writeln(globalMoves[q][2]);
        writeln(globalMoves[q][3]);
        if (globalMoves[q+1][1] <> '0') then begin
            writeln('---');
        end;

    end;

    if (globalMoves[1][1] = '0') then begin
        writeln('unsat');
    end;

end.