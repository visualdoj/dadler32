{$MODE FPC}
{$MODESWITCH RESULT}

uses
  dadler32;

// Reimplemented ALDER-32 to be compared with dadler32
function ReferenceAdler32(Data, DataEnd: PByte;
                          Adler: Cardinal): Cardinal;
var
  S1, S2: PtrUInt;
begin
  S1 := Adler and $ffff;
  S2 := (Adler shr 16) and $ffff;
  while Data < DataEnd do begin
    S1 := (S1 + Data^) mod 65521;
    S2 := (S2 + S1) mod 65521;
    Inc(Data);
  end;
  Exit((S2 shl 16) or S1);
end;

const
  SIMPLE_CASES: array[0 .. 30 - 1] of AnsiString = (
    '',
    'a',
    'ab',
    'abc',
    'abcd',
    'abcdefg',
    'abcdefgh',
    'abcdefghi',
    'abcdefghij',
    'abcdefghijk',
    'abcdefghijkl',
    'abcdefghijklm',
    'abcdefghijklmn',
    'abcdefghijklmno',
    'abcdefghijklmnop',
    'abcdefghijklmnopq',
    'abcdefghijklmnopqr',
    'abcdefghijklmnopqrs',
    'abcdefghijklmnopqrst',
    'abcdefghijklmnopqrstu',
    'abcdefghijklmnopqrstuv',
    'abcdefghijklmnopqrstuvw',
    'abcdefghijklmnopqrstuvwx',
    'abcdefghijklmnopqrstuvwxy',
    'abcdefghijklmnopqrstuvwxyz',
    'abcdefghijklmnopqrstuvwxyz',
    'abcdefghijklmnopqrstuvwxyz0123456789',
    #0,
    #0#0#0#0#0#0#0,
    #255#255#255#255
  );

function MakePrintable(const S: AnsiString): AnsiString;
var
  I: LongInt;
begin
  Result := '';
  for I := 1 to Length(S) do begin
    if S[I] in ['a'..'z','A'..'Z','0'..'9','-','+','_'] then begin
      Result := Result + S[I];
    end else
      Result := Result + '\x' + HexStr(Ord(S[I]), 2);
    if I > 40 then
      Exit(Result + '...');
  end;
end;

function GenerateHuge(const Pattern: AnsiString; Repeats: LongInt): AnsiString;
var
  Cursor: PAnsiChar;
  Portion: SizeUInt;
begin
  if Length(Pattern) <= 0 then
    Exit('');
  SetLength(Result, Length(Pattern) * Repeats);
  Cursor := @Result[1] + Length(Pattern);
  Move(Pattern[1], Result[1], Length(Pattern));
  while Cursor < @Result[1] + Length(Result) do begin
    Portion := Cursor - @Result[1];
    if Portion > Length(Result) - (Cursor - @Result[1]) then
      Portion := Length(Result) - (Cursor - @Result[1]);
    Move(Result[1], Cursor^, Portion);
    Inc(Cursor, Portion);
  end;
end;

var
  I: LongInt;
  ErrorCode: LongInt;

procedure TestString(const S: AnsiString);
var
  Adler, ReferenceAdler: UInt32;
begin
  Adler := Adler32(@S[1], Length(S));
  ReferenceAdler := ReferenceAdler32(@S[1], @S[1] + Length(S), 1);
  if Adler <> ReferenceAdler then begin
    Writeln(stderr, 'FAILED for "', MakePrintable(S), '": expected ', HexStr(ReferenceAdler, 8), ', got ', HexStr(Adler, 8));
    ErrorCode := 1;
  end;
end;

begin
  ErrorCode := 0;
  for I := 0 to High(SIMPLE_CASES) do
    TestString(SIMPLE_CASES[I]);
  TestString(GenerateHuge('HUGE1', 100 * 5552));
  TestString(GenerateHuge('HUGE2', 500 * 5552));
  TestString(GenerateHuge('HUGE3', 1 shl 20));
  TestString(GenerateHuge(#255#255#255#255#255, 1 shl 20));
  if ErrorCode <> 0 then
    Halt(ErrorCode);
end.
