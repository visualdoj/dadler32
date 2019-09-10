unit dadler32;
//
//  Implementation of ADLER-32 checksum.
//
//  The algorithm is defined in RFC-1950:
//      https://www.ietf.org/rfc/rfc1950.txt
//

{$MODE FPC}
{$MODESWITCH RESULT}

interface

function Adler32(Buf: Pointer; Len: SizeUInt): UInt32; inline; overload;
function Adler32(Buf, BufEnd: Pointer): UInt32; inline; overload;
      //  Returns ADLER-32 checksum for the specified data.
      //  BufEnd is alternative way to specify buffer, BufEnd=Buf+Len.

function UpdateAdler32(Adler: UInt32;
                       Buf: Pointer;
                       Len: SizeUInt): UInt32; inline; overload;
function UpdateAdler32(Adler: UInt32;
                       Buf: Pointer;
                       BufEnd: Pointer): UInt32; inline; overload;
      //  Updates the specified Adler checksum and returns new value. Works
      //  like if the buffer (specified with Buf,Len or Buf,BufEnd pair) was
      //  appended to previous data. Initial adler checksum (i.e. for empty
      //  data) is 1.
      //  BufEnd is alternative way to specify buffer, BufEnd=Buf+Len.

implementation

function Adler32(Buf: Pointer; Len: SizeUInt): UInt32;
begin
  Result := UpdateAdler32(1, Buf, Buf + Len);
end;

function Adler32(Buf, BufEnd: Pointer): UInt32;
begin
  Result := UpdateAdler32(1, Buf, BufEnd);
end;

function UpdateAdler32(Adler: UInt32;
                       Buf: Pointer;
                       Len: SizeUInt): UInt32;
begin
  Result := UpdateAdler32(Adler, Buf, Buf + Len);
end;

function ComputeAdler32Sums4Bytes(Value: UInt32; S1: UInt32; var S2: UInt32): UInt32; inline;
      //  Updates S1 and S2 for 4 bytes in Value.
      //  Returns new S1, updates S2 in-place.
begin
{$IFDEF ENDIAN_LITTLE}
  Inc(S1, Value and $ff);
  Inc(S2, S1);
  Inc(S1, (Value shr 8) and $ff);
  Inc(S2, S1);
  Inc(S1, (Value shr 16) and $ff);
  Inc(S2, S1);
  Inc(S1, Value shr 24);
  Inc(S2, S1);
{$ELSE}
  Inc(S1, Value shr 24);
  Inc(S2, S1);
  Inc(S1, (Value shr 16) and $ff);
  Inc(S2, S1);
  Inc(S1, (Value shr 8) and $ff);
  Inc(S2, S1);
  Inc(S1, Value and $ff);
  Inc(S2, S1);
{$ENDIF}
  Exit(S1);
end;

procedure ComputeAdler32Sums(Buf, BufEnd: Pointer; var S1, S2: UInt32);
      // Updates S1 and S2 without modulo.
begin
  // The main loop, should be optimized
  while Buf + 16 <= BufEnd do begin
    // Unrolled calculation
    S1 := ComputeAdler32Sums4Bytes(PUInt32(Buf +  0)^, S1, S2);
    S1 := ComputeAdler32Sums4Bytes(PUInt32(Buf +  4)^, S1, S2);
    S1 := ComputeAdler32Sums4Bytes(PUInt32(Buf +  8)^, S1, S2);
    S1 := ComputeAdler32Sums4Bytes(PUInt32(Buf + 12)^, S1, S2);
    Inc(Buf, 16);
  end;
  // Compute rest bytes
  while Buf < BufEnd do begin
    Inc(S1, Byte(Buf^));
    Inc(S2, S1);
    Inc(Buf);
  end;
end;

function UpdateAdler32(Adler: UInt32;
                       Buf: Pointer;
                       BufEnd: Pointer): UInt32;
var
  S1, S2: UInt32;
  PortionSize: SizeUInt;
begin
  S1 := Adler and $ffff;
  S2 := (Adler shr 16) and $ffff;
  while Buf < BufEnd do begin
    // "The modulo on unsigned long accumulators can be delayed for 5552 bytes"
    PortionSize := 5552;
    if PortionSize > BufEnd - Buf then
      PortionSize := BufEnd - Buf;
    ComputeAdler32Sums(Buf, Buf + PortionSize, S1, S2);
    S1 := S1 mod 65521;
    S2 := S2 mod 65521;
    Inc(Buf, PortionSize);
  end;
  Exit((S2 shl 16) or S1);
end;

end.
