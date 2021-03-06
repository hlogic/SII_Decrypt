{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decrypt_Header;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  AuxTypes; // provides types that are not guaranteed to be present in all compilers

{
  Types used in this unit (in case anyone will be translating this unit to other
  languages):

    Pointer   - general, untyped pointer
    PPointer  - pointer to untyped pointer
    TMemSize  - unsigned integer the size of pointer (8 bytes on 64bit system,
                4 bytes on 32bit system)
    PMemSize  - pointer to an unsigned pointer-sized integer
    Int32     - signed 32bit integer
    PUTF8Char - pointer to the first character of UTF8-encoded, null-terminated
                string
    LongBool  = 32bit wide boolean value (0 = False; any other value = True)

}

const
{
  Following are all possible values any library function can return.
  For meaning of individual values, refer to description of functions that
  returns them.
  If any function returns value that is not listed here, you should process it
  as if it returned SIIDEC_RESULT_GENERIC_ERROR.
}
  SIIDEC_RESULT_GENERIC_ERROR    = -1;
  SIIDEC_RESULT_SUCCESS          = 0;
  SIIDEC_RESULT_NOT_ENCRYPTED    = 1;
  SIIDEC_RESULT_BINARY_FORMAT    = 2;
  SIIDEC_RESULT_UNKNOWN_FORMAT   = 3;
  SIIDEC_RESULT_TOO_FEW_DATA     = 4;
  SIIDEC_RESULT_BUFFER_TOO_SMALL = 5;

//==============================================================================

var
{-------------------------------------------------------------------------------

  GetMemoryFormat

  Returns format of the passed memory buffer.
  The format is discerned acording to first four bytes (signature) and the size
  is then checked againts that format (must be high enough to contain valid
  data for the given format).

  Parameters:

    Mem  - Pointer to a memory block that should be scanned (must not be nil)
    Size - Size of the memory block in bytes

  Returns:

    SIIDEC_RESULT_GENERIC_ERROR    - an unhandled exception have occured
    SIIDEC_RESULT_SUCCESS          - memory contains encrypted SII file
    SIIDEC_RESULT_NOT_ENCRYPTED    - memory contains plain-text SII file
    SIIDEC_RESULT_BINARY_FORMAT    - memory contains binary form of SII file
    SIIDEC_RESULT_UNKNOWN_FORMAT   - memory contains unknown data
    SIIDEC_RESULT_TOO_FEW_DATA     - memory buffer is too small to contain valid
                                     data for its format
    SIIDEC_RESULT_BUFFER_TOO_SMALL - not returned by this function
}
  GetMemoryFormat: Function(Mem: Pointer; Size: TMemSize): Int32; stdcall;

{-------------------------------------------------------------------------------

  GetFileFormat

  Returns format of file given by its name (path).
  It is recommended to pass full file path, but relative path is acceptable.
  If the file does not exists, a generic error code is returned.
  The format is discerned acording to first four bytes (signature) and the size
  is then checked againts that format (must be high enough to contain valid
  data for the given format).

  Parameters:

    FileName - path to the file that should be scanned

  Returns:

    SIIDEC_RESULT_GENERIC_ERROR    - an unhandled exception have occured
    SIIDEC_RESULT_SUCCESS          - encrypted SII file
    SIIDEC_RESULT_NOT_ENCRYPTED    - plain-text SII file
    SIIDEC_RESULT_BINARY_FORMAT    - binary form of SII file
    SIIDEC_RESULT_UNKNOWN_FORMAT   - file of an uknown format
    SIIDEC_RESULT_TOO_FEW_DATA     - file is too small to contain valid data for
                                     its format
    SIIDEC_RESULT_BUFFER_TOO_SMALL - not returned by this function
}
  GetFileFormat: Function(FileName: PUTF8Char): Int32; stdcall;

{-------------------------------------------------------------------------------

  IsEncryptedMemory

  Checks whether the passed memory buffer contains an encrypted SII file.

  Parameters:

    Mem  - Pointer to a memory block that should be checked (must not be nil)
    Size - Size of the memory block in bytes

  Returns:

    Zero (false) when the buffer DOES NOT contain an encrypted SII file. When it
    DOES contain an encrypted SII file, it returns non-zero value (true).
}
  IsEncryptedMemory: Function(Mem: Pointer; Size: TMemSize): LongBool; stdcall;

{-------------------------------------------------------------------------------

  IsEncryptedFile

  Checks whether the given file contains an encrypted SII file.
  It is recommended to pass full file path, but relative path is acceptable.
  If the file does not exists, zero (false) is returned.

  Parameters:

    FileName - path to the file that should be checked

  Returns:

    Zero (false) when the file is NOT an encrypted SII file. When it IS an
    encrypted SII file, it returns non-zero value (true).
}
  IsEncryptedFile: Function(FileName: PUTF8Char): LongBool; stdcall;

{-------------------------------------------------------------------------------

  IsEncodedMemory

  Checks whether the passed memory buffer contains a binary SII file.

  Parameters:

    Mem  - Pointer to a memory block that should be checked (must not be nil)
    Size - Size of the memory block in bytes

  Returns:

    Zero (false) when the buffer DOES NOT contain a binary SII file. When it
    DOES contain a binary SII file, it returns non-zero value (true).
}
  IsEncodedMemory: Function(Mem: Pointer; Size: TMemSize): LongBool; stdcall;

{-------------------------------------------------------------------------------

  IsEncodedFile

  Checks whether the given file contains a binary SII file.
  It is recommended to pass full file path, but relative path is acceptable.
  If the file does not exists, zero (false) is returned.

  Parameters:

    FileName - path to the file that should be checked

  Returns:

    Zero (false) when the file is NOT a binary SII file. When it IS a binary SII
    file, it returns non-zero value (true).
}
  IsEncodedFile: Function(FileName: PUTF8Char): LongBool; stdcall;

{-------------------------------------------------------------------------------

  DecryptMemory

  Decrypts memory block given by the Input parameter and stores decrypted data
  to a memory given by Output parameter.
  To properly use this function, you have to call it twice. Do following:

    - call this function with parameter Output set to nil (null/0), variable
      pointed to by OutSize pointer can contain any value
    - if the function returns SIIDEC_RESULT_SUCCESS, then minimal size of output
      buffer is stored in a variable pointed to by parameter OutSize, otherwise
      stop here and do not continue with next step
    - use returned min. size of output buffer to allocate buffer for the next
      step
    - call this function again, this time with Output set to a buffer allocated
      in previous step and value of variable pointed to by OutSize set to a size
      of the allocated output buffer
    - if the function returns SIIDEC_RESULT_SUCCESS, then true size of decrypted
      data will be stored to a variable pointed to by parameter OutSize and
      decrypted data will be stored to buffer passed in Output parameter,
      otherwise nothing is stored in any output

  Parameters:

    Input   - pointer to a memory block containing input data (encrypted SII
              file) (must not be nil)
    InSize  - size of the input data in bytes
    Output  - pointer to a buffer that will receive decrypted data
    OutSize - pointer to a variable holding size of the output buffer, on return
              receives true size of the decryted data (in bytes)

  Returns:

    SIIDEC_RESULT_GENERIC_ERROR    - an unhandled exception have occured
    SIIDEC_RESULT_SUCCESS          - input data were successfully decrypted and
                                     result stored in the output buffer
    SIIDEC_RESULT_NOT_ENCRYPTED    - input data contains plain-text SII file
                                     (does not need decryption)
    SIIDEC_RESULT_BINARY_FORMAT    - input data contains binary form of SII file
                                     (does not need decryption)
    SIIDEC_RESULT_UNKNOWN_FORMAT   - input data is of an uknown format
    SIIDEC_RESULT_TOO_FEW_DATA     - input buffer is too small to contain
                                     complete encrypted SII file header
    SIIDEC_RESULT_BUFFER_TOO_SMALL - size of the output buffer given in OutSize
                                     is too small to store all decrypted data
}
  DecryptMemory: Function(Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32; stdcall;
  
{-------------------------------------------------------------------------------

  DecryptFile

  Decrypts file given by a path in InputFile parameter and stores decrypted
  result in a file given by a path in OutputFile parameter.
  It is recommended to pass full file paths, but relative paths are acceptable.
  Folder, where the destination file will be stored, must exists prior of
  calling this function, otherwise it fails with SIIDEC_RESULT_GENERIC_ERROR.
  It is allowed to pass the same file as input and output.

  Parameters:

    Input  - path to the source file (encrypted SII file)
    Output - path to the destination file (where decrypted result will be stored)

  Returns:

    SIIDEC_RESULT_GENERIC_ERROR    - an unhandled exception have occured
    SIIDEC_RESULT_SUCCESS          - input file was successfully decrypted and
                                     result stored in the output file
    SIIDEC_RESULT_NOT_ENCRYPTED    - input file contains plain-text SII file
                                     (does not need decryption)
    SIIDEC_RESULT_BINARY_FORMAT    - input file contains binary form of SII file
                                     (does not need decryption)
    SIIDEC_RESULT_UNKNOWN_FORMAT   - input file is of an uknown format
    SIIDEC_RESULT_TOO_FEW_DATA     - input file is too small to contain complete
                                     encrypted SII file header
    SIIDEC_RESULT_BUFFER_TOO_SMALL - not returned by this function
}
  DecryptFile: Function(InputFile,OutputFile: PUTF8Char): Int32; stdcall;

{-------------------------------------------------------------------------------

  DecodeMemoryHelper

  Decodes (converts binary data to their textual form) memory block given by the
  Input parameter and stores decoded data to a memory given by Output parameter.
  Use of this function is somewhat complex, but it can be split into two, let's
  say, paths - one where you use the provided Helper parameter, and one where
  you don't.

  When you will use the helper, do following:

    - call this function with parameter Output set to nil (null/0), variable
      pointed to by OutSize pointer can contain any value, Helper must contain
      a valid pointer to pointer
    - if the function returns SIIDEC_RESULT_SUCCESS, then minimal size of output
      buffer is stored in a variable pointed to by parameter OutSize and
      variable pointed to by Helper parameter receives helper object, otherwise
      stop here and do not continue with next step
    - use returned min. size of output buffer to allocate buffer for the next
      step
    - call this function again, this time with Output set to a buffer allocated
      in previous step, value of variable pointed to by OutSize set to a size
      of the allocated output buffer and Helper pointing to the same variable as
      in first call
    - if the function returns SIIDEC_RESULT_SUCCESS, then true size of decoded
      data will be stored to a variable pointed to by parameter OutSize,
      decoded data will be stored to buffer passed in Output parameter and
      helper object will be consumed and freed, otherwise nothing is stored in
      any output and you have to free the helper object using function
      FreeHelper

  If you won't use the helper, set the parameter Helper to nil. The procedure is
  then the same as with the function DecryptMemory, so refer there.

  This function cannot determine the size of result before actual decoding is
  complete. So when you ask it for size of output buffer, it will do complete
  decoding, which may be quite a long process (several seconds).
  Helper is there to speed things up - when you use it (pass valid pointer), the
  function stores helper object (DO NOT assume anything about it, consider it
  being completely opaque) to a variable pointed to by Helper parameter. When
  you allocate output buffer and call the function again, pass this returned
  helper and the function will, instead of decoding the data again, only copy
  data from decoding done in the first iteration.
  WARNING - if you don't call the function second time or if the function fails
  in the second call, you have to manually free the helper using function
  FreeHelper, otherwise it will result in serious memory leak (tens of MiB).
  Given mentioned facts, it is strongly recommended to use the helper whenever
  possible, but with caution.

  Parameters:

    Input   - pointer to a memory block containing input data (binary SII
              file) (must not be nil)
    InSize  - size of the input data in bytes
    Output  - pointer to a buffer that will receive decoded data
    OutSize - pointer to a variable holding size of the output buffer, on return
              receives true size of the decoded data (in bytes)
    Helper  - pointer to a variable that will receive or contains helper

  Returns:

    SIIDEC_RESULT_GENERIC_ERROR    - an unhandled exception have occured
    SIIDEC_RESULT_SUCCESS          - input data were successfully decoded and
                                     result stored in the output buffer
    SIIDEC_RESULT_NOT_ENCRYPTED    - input data contains plain-text SII file
                                     (does not need decoding)
    SIIDEC_RESULT_BINARY_FORMAT    - not returned by this function
    SIIDEC_RESULT_UNKNOWN_FORMAT   - input data is of an uknown format or it is
                                     an encrypted SII file
    SIIDEC_RESULT_TOO_FEW_DATA     - input buffer is too small to contain valid
                                     binary SII file
    SIIDEC_RESULT_BUFFER_TOO_SMALL - size of the output buffer given in OutSize
                                     is too small to store all decoded data
}
  DecodeMemoryHelper: Function(Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize; Helper: PPointer): Int32; stdcall;

{-------------------------------------------------------------------------------

  DecodeMemory

  Decodes (converts binary data to their textual form) memory block given by the
  Input parameter and stores decoded data to a memory given by Output parameter.
  Use of this function is exactly the same as for DecodeMemoryHelper when you do
  not use helper, so refer there for details.

  Parameters:

    Input   - pointer to a memory block containing input data (binary SII
              file) (must not be nil)
    InSize  - size of the input data in bytes
    Output  - pointer to a buffer that will receive decoded data
    OutSize - pointer to a variable holding size of the output buffer, on return
              receives true size of the decoded data (in bytes)

  Returns:

    SIIDEC_RESULT_GENERIC_ERROR    - an unhandled exception have occured
    SIIDEC_RESULT_SUCCESS          - input data were successfully decoded and
                                     result stored in the output buffer
    SIIDEC_RESULT_NOT_ENCRYPTED    - input data contains plain-text SII file
                                     (does not need decoding)
    SIIDEC_RESULT_BINARY_FORMAT    - not returned by this function
    SIIDEC_RESULT_UNKNOWN_FORMAT   - input data is of an uknown format or it is
                                     an encrypted SII file
    SIIDEC_RESULT_TOO_FEW_DATA     - input buffer is too small to contain valid
                                     binary SII file
    SIIDEC_RESULT_BUFFER_TOO_SMALL - size of the output buffer given in OutSize
                                     is too small to store all decoded data
}
  DecodeMemory: Function(Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32; stdcall;

{-------------------------------------------------------------------------------

  DecodeFile

  Decodes file given by a path in InputFile parameter and stores decoded result
  in a file given by a path in OutputFile parameter.
  It is recommended to pass full file paths, but relative paths are acceptable.
  Folder, where the destination file will be stored, must exists prior of
  calling this function, otherwise it fails with SIIDEC_RESULT_GENERIC_ERROR.
  It is allowed to pass the same file as input and output.

  Parameters:

    Input  - path to the source file (binary SII file)
    Output - path to the destination file (where decoded result will be stored)

  Returns:

    SIIDEC_RESULT_GENERIC_ERROR    - an unhandled exception have occured
    SIIDEC_RESULT_SUCCESS          - input file was successfully decoded and
                                     result stored in the output file
    SIIDEC_RESULT_NOT_ENCRYPTED    - input file contains plain-text SII file
                                     (does not need decoding)
    SIIDEC_RESULT_BINARY_FORMAT    - not returned by this function
    SIIDEC_RESULT_UNKNOWN_FORMAT   - input file is of an uknown format or it is
                                     an encrypted SII file
    SIIDEC_RESULT_TOO_FEW_DATA     - input file is too small to contain a valid
                                     binary SII file
    SIIDEC_RESULT_BUFFER_TOO_SMALL - not returned by this function
}
  DecodeFile: Function(InputFile,OutputFile: PUTF8Char): Int32; stdcall;

{-------------------------------------------------------------------------------

  DecryptAndDecodeMemoryHelper

  Decrypts and, if needed, decodes memory block given by the Input parameter and
  stores decoded data to a memory given by Output parameter.
  Use is exactly the same as in function DecodeMemoryHelper, refer there for
  details about how to properly use this function

  Parameters:

    Input   - pointer to a memory block containing input data (encrypted or
              binary SII file) (must not be nil)
    InSize  - size of the input data in bytes
    Output  - pointer to a buffer that will receive decrypted and decoded data
    OutSize - pointer to a variable holding size of the output buffer, on return
              receives true size of the decrypted and decoded data (in bytes)
    Helper  - pointer to a variable that will receive or contains helper

  Returns:

    SIIDEC_RESULT_GENERIC_ERROR    - an unhandled exception have occured
    SIIDEC_RESULT_SUCCESS          - input data were successfully decrypted and
                                     decoded and result stored in the output
                                     buffer
    SIIDEC_RESULT_NOT_ENCRYPTED    - input data contains plain-text SII file
                                     (does not need decryption or decoding)
    SIIDEC_RESULT_BINARY_FORMAT    - not returned by this function
    SIIDEC_RESULT_UNKNOWN_FORMAT   - input data is of an uknown format
    SIIDEC_RESULT_TOO_FEW_DATA     - input buffer is too small to contain valid
                                     encrypted or binary SII file
    SIIDEC_RESULT_BUFFER_TOO_SMALL - size of the output buffer given in OutSize
                                     is too small to store all decrypted and
                                     decoded data
}
  DecryptAndDecodeMemoryHelper: Function(Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize; Helper: PPointer): Int32; stdcall;

{-------------------------------------------------------------------------------

  DecryptAndDecodeMemory

  Decrypts and, if needed, decodes memory block given by the Input parameter and
  stores decoded data to a memory given by Output parameter.
  Use is exactly the same as in function DecodeMemory, refer there for details
  about how to properly use this function

  Parameters:

    Input   - pointer to a memory block containing input data (encrypted or
              binary SII file) (must not be nil)
    InSize  - size of the input data in bytes
    Output  - pointer to a buffer that will receive decrypted and decoded data
    OutSize - pointer to a variable holding size of the output buffer, on return
              receives true size of the decrypted and decoded data (in bytes)

  Returns:

    SIIDEC_RESULT_GENERIC_ERROR    - an unhandled exception have occured
    SIIDEC_RESULT_SUCCESS          - input data were successfully decrypted and
                                     decoded and result stored in the output
                                     buffer
    SIIDEC_RESULT_NOT_ENCRYPTED    - input data contains plain-text SII file
                                     (does not need decryption or decoding)
    SIIDEC_RESULT_BINARY_FORMAT    - not returned by this function
    SIIDEC_RESULT_UNKNOWN_FORMAT   - input data is of an uknown format
    SIIDEC_RESULT_TOO_FEW_DATA     - input buffer is too small to contain valid
                                     encrypted or binary SII file
    SIIDEC_RESULT_BUFFER_TOO_SMALL - size of the output buffer given in OutSize
                                     is too small to store all decrypted and
                                     decoded data
}
  DecryptAndDecodeMemory: Function(Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32; stdcall;

{-------------------------------------------------------------------------------

  DecryptAndDecodeFile

  Decrypts and, if needed, decodes file given by a path in InputFile parameter
  and stores the result in a file given by a path in OutputFile parameter.
  It is recommended to pass full file paths, but relative paths are acceptable.
  Folder, where the destination file will be stored, must exists prior of
  calling this function, otherwise it fails with SIIDEC_RESULT_GENERIC_ERROR.
  It is allowed to pass the same file as input and output.

  Parameters:

    Input  - path to the source file (ecrypted or binary SII file)
    Output - path to the destination file (where decrypted and decoded result
             will be stored)

  Returns:

    SIIDEC_RESULT_GENERIC_ERROR    - an unhandled exception have occured
    SIIDEC_RESULT_SUCCESS          - input file was successfully decrypted and
                                     decoded and result stored in the output file
    SIIDEC_RESULT_NOT_ENCRYPTED    - input file contains plain-text SII file
                                     (does not need decryption or decoding)
    SIIDEC_RESULT_BINARY_FORMAT    - not returned by this function
    SIIDEC_RESULT_UNKNOWN_FORMAT   - input file is of an uknown format
    SIIDEC_RESULT_TOO_FEW_DATA     - input file is too small to contain a valid
                                     encrypted or binary SII file
    SIIDEC_RESULT_BUFFER_TOO_SMALL - not returned by this function
}
  DecryptAndDecodeFile: Function(InputFile,OutputFile: PUTF8Char): Int32; stdcall;

{-------------------------------------------------------------------------------

  FreeHelper

  Frees resources taken by a helper object allocated by DecodeMemoryHelper or
  DecryptAndDecodeMemoryHelper function. Refer to those functions documentation
  for details about when you have to call this function and when you don't.
  Passing in an already freed object is allowed, the function just returns
  immediately.

  Parameters:

    Helper - Pointer to a variable containing helper object to be freed

  Returns:

    This routine does not have a return value.
}
  FreeHelper: procedure(Helper: PPointer); stdcall;

//==============================================================================

const
  // Default file name of the dynamically loaded library (DLL).
  SIIDecrypt_LibFileName = 'SII_Decrypt.dll';

// Call this routine to initialize (load) the dynamic library.
procedure Load_SII_Decrypt(const LibraryFile: String = 'SII_Decrypt.dll');

// Call this routine to free (unload) the dynamic library.
procedure Unload_SII_Decrypt;

implementation
      
uses
  SysUtils, Windows;

//==============================================================================

var
  LibHandle:  HMODULE;

procedure Load_SII_Decrypt(const LibraryFile: String = SIIDecrypt_LibFileName);
begin
If LibHandle = 0 then
  begin
    LibHandle := LoadLibrary(PChar(LibraryFile));
    If LibHandle <> 0 then
      begin
        GetMemoryFormat   := GetProcAddress(LibHandle,'GetMemoryFormat');
        GetFileFormat     := GetProcAddress(LibHandle,'GetFileFormat');
        IsEncryptedMemory := GetProcAddress(LibHandle,'IsEncryptedMemory');
        IsEncryptedFile   := GetProcAddress(LibHandle,'IsEncryptedFile');
        IsEncodedMemory   := GetProcAddress(LibHandle,'IsEncodedMemory');
        IsEncodedFile     := GetProcAddress(LibHandle,'IsEncodedFile');

        DecryptMemory := GetProcAddress(LibHandle,'DecryptMemory');
        DecryptFile   := GetProcAddress(LibHandle,'DecryptFile');

        DecodeMemoryHelper := GetProcAddress(LibHandle,'DecodeMemoryHelper');
        DecodeMemory       := GetProcAddress(LibHandle,'DecodeMemory');
        DecodeFile         := GetProcAddress(LibHandle,'DecodeFile');

        DecryptAndDecodeMemoryHelper := GetProcAddress(LibHandle,'DecryptAndDecodeMemoryHelper');
        DecryptAndDecodeMemory       := GetProcAddress(LibHandle,'DecryptAndDecodeMemory');
        DecryptAndDecodeFile         := GetProcAddress(LibHandle,'DecryptAndDecodeFile');

        FreeHelper := GetProcAddress(LibHandle,'FreeHelper');
      end
    else raise Exception.CreateFmt('Unable to load library %s.',[LibraryFile]);
  end;
end;

//------------------------------------------------------------------------------

procedure Unload_SII_Decrypt;
begin
If LibHandle <> 0 then
  begin
    FreeLibrary(LibHandle);
    LibHandle := 0;
  end;
end;

end.
