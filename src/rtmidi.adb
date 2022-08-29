with Interfaces.C.Strings; use Interfaces.C.Strings;
with Interfaces.C; use Interfaces.C;

with Ada.Unchecked_Deallocation;

package body RtMIDI is

   type RtMIDIWrapper is record
      Ptr : System.Address;
      Data : System.Address;

      Ok : Interfaces.C.Extensions.bool;

      Msg : char_array_access;
   end record;

   -----------
   -- Error --
   -----------

   function Error (Device : MIDI_Any) return Boolean
   is
      Wrapper : RtMIDIWrapper
        with Import, Address => System.Address (Device);
   begin
      return not Boolean (Wrapper.Ok);
   end Error;

   -------------------
   -- Error_Message --
   -------------------

   function Error_Message (Device : MIDI_Any) return String is
      Wrapper : RtMIDIWrapper
        with Import, Address => System.Address (Device);
   begin
      if Boolean (Wrapper.Ok) or else Wrapper.Msg = null then
         return "No error";
      end if;

      return To_Ada (Wrapper.Msg.all);
   end Error_Message;

   --------------------------
   -- Available_Port_Count --
   --------------------------

   function Available_Port_Count (Device : MIDI_Any) return Natural is
   begin
      return Natural (rtmidi_get_port_count (Device));
   end Available_Port_Count;

   ---------------
   -- Port_Name --
   ---------------

   function Port_Name (Device     : MIDI_Any;
                       Port_Numer : Positive)
                       return String
   is
      Len : aliased int;
      Err : int;
   begin
      Err := rtmidi_get_port_name (Device,
                                   unsigned (Port_Numer),
                                   bufOut => Null_Ptr,
                                   bufLen => Len'Access);
      if Err < 0 or else Len <= 0 then
         return "";
      end if;

      declare
         procedure Free
         is new Ada.Unchecked_Deallocation (char_array, char_array_access);

         C_Str : char_array_access := new char_array (1 .. size_t (Len));
      begin
         Err := rtmidi_get_port_name (Device,
                                      unsigned (Port_Numer),
                                      bufOut => To_Chars_Ptr (C_Str),
                                      bufLen => Len'Access);
         if Err < 0 then
            return "";
         end if;

         return Result : constant String := To_Ada (C_Str.all) do
            Free (C_Str);
         end return;
      end;
   end Port_Name;

   --------------------
   -- Create_Default --
   --------------------

   function Create_Default return MIDI_In is
   begin
      return MIDI_In (rtmidi_in_create_default);
   end Create_Default;

   ------------
   -- Create --
   ------------

   function Create (Device_Name      : String;
                    API              : RtMidiApi := API_UNSPECIFIED;
                    Queue_Size_Limit : Natural := 100)
                    return MIDI_In
   is
      Ret : MIDI_In;
      C_Name : chars_ptr := New_String (Device_Name);
   begin
      Ret := rtmidi_in_create (API, C_Name, unsigned (Queue_Size_Limit));
      Free (C_Name);
      return Ret;
   end Create;

   ----------
   -- Free --
   ----------

   procedure Free (Device : in out MIDI_In) is
   begin
      rtmidi_in_free (Device);
      Device := MIDI_In (System.Null_Address);
   end Free;

   --------------------------
   -- Available_Port_Count --
   --------------------------

   function Available_Port_Count (Device : MIDI_In) return Natural
   is (Available_Port_Count (MIDI_Any (Device)));

   ---------------
   -- Port_Name --
   ---------------

   function Port_Name (Device     : MIDI_In;
                       Port_Numer : Positive)
                       return String
   is (Port_Name (MIDI_Any (Device), Port_Numer));

   ---------------
   -- Open_Port --
   ---------------

   procedure Open_Port (Device      : MIDI_In;
                        Port_Number : Natural;
                        Name        : String)
   is
      C_Name : chars_ptr := New_String (Name);
   begin
      rtmidi_open_port (MIDI_Any (Device),
                        Interfaces.C.unsigned (Port_Number),
                        C_Name);
      Free (C_Name);
   end Open_Port;

   -------------------------
   -- Create_Virtual_Port --
   -------------------------

   procedure Create_Virtual_Port (Device : MIDI_In;
                                  Name   : String := "RtMIDI Input")
   is
      C_Name : chars_ptr := New_String (Name);
   begin
      rtmidi_open_virtual_port (MIDI_Any (Device), C_Name);
      Free (C_Name);
   end Create_Virtual_Port;

   ----------------
   -- Close_Port --
   ----------------

   procedure Close_Port (Device : MIDI_In) is
   begin
      rtmidi_close_port (MIDI_Any (Device));
   end Close_Port;

   ---------------------
   -- Ignore_Messages --
   ---------------------

   procedure Ignore_Messages (Device : MIDI_In;
                              SysEx  : Boolean;
                              Time   : Boolean;
                              Sense  : Boolean)
   is
   begin
      rtmidi_in_ignore_types (Device,
                              Interfaces.C.Extensions.bool (SysEx),
                              Interfaces.C.Extensions.bool (Time),
                              Interfaces.C.Extensions.bool (Sense));
   end Ignore_Messages;

   -----------------
   -- Get_Message --
   -----------------

   function Get_Message (Device : MIDI_In)
                         return System.Storage_Elements.Storage_Array
   is
      use System.Storage_Elements;
      Message : Storage_Array (1 .. 1024);
      Size    : aliased size_t;

      Unused : double;
   begin

      Unused := Get_Message (Device, Message'Address, Size'Access);

      return Message (1 .. Storage_Offset (Size));
   end Get_Message;

   -----------------
   -- Get_Message --
   -----------------

   function Get_Message (Device  : MIDI_In;
                         Message : System.Address;
                         Size    : not null access Interfaces.C.size_t)
                         return Interfaces.C.double
   is
   begin
      return rtmidi_in_get_message (Device, Message, Size);
   end Get_Message;

   ------------------
   -- Set_Callback --
   ------------------

   procedure Set_Callback (Device    : MIDI_In;
                           Callback  : Input_Callback_C;
                           User_Data : System.Address := System.Null_Address)
   is
   begin
      if Callback /= null then
         rtmidi_in_set_callback (Device, Callback, User_Data);
      else
         rtmidi_in_cancel_callback (Device);
      end if;
   end Set_Callback;

   -----------
   -- Error --
   -----------

   function Error (Device : MIDI_In) return Boolean
   is (Error (MIDI_Any (Device)));

   -------------------
   -- Error_Message --
   -------------------

   function Error_Message (Device : MIDI_In) return String
   is (Error_Message (MIDI_Any (Device)));

   --------------------
   -- Create_Default --
   --------------------

   function Create_Default return MIDI_Out is
   begin
      return MIDI_Out (rtmidi_out_create_default);
   end Create_Default;

   ------------
   -- Create --
   ------------

   function Create (Device_Name : String;
                    API         : RtMidiApi := API_UNSPECIFIED)
                    return MIDI_Out
   is
      Ret : MIDI_Out;
      C_Name : chars_ptr := New_String (Device_Name);
   begin
      Ret := rtmidi_out_create (API, C_Name);
      Free (C_Name);
      return Ret;
   end Create;

   ----------
   -- Free --
   ----------

   procedure Free (Device : in out MIDI_Out) is
   begin
      rtmidi_out_free (Device);
      Device := MIDI_Out (System.Null_Address);
   end Free;

   --------------------------
   -- Available_Port_Count --
   --------------------------

   function Available_Port_Count (Device : MIDI_Out) return Natural
   is (Available_Port_Count (MIDI_Any (Device)));

   ---------------
   -- Port_Name --
   ---------------

   function Port_Name (Device     : MIDI_Out;
                       Port_Numer : Positive)
                       return String
   is (Port_Name (MIDI_Any (Device), Port_Numer));

   ---------------
   -- Open_Port --
   ---------------

   procedure Open_Port (Device      : MIDI_Out;
                        Port_Number : Natural;
                        Name        : String)
   is
      C_Name : chars_ptr := New_String (Name);
   begin
      rtmidi_open_port (MIDI_Any (Device),
                        Interfaces.C.unsigned (Port_Number),
                        C_Name);
      Free (C_Name);
   end Open_Port;

   -------------------------
   -- Create_Virtual_Port --
   -------------------------

   procedure Create_Virtual_Port (Device : MIDI_Out;
                                  Name   : String := "RtMidi Output")
   is
      C_Name : chars_ptr := New_String (Name);
   begin
      rtmidi_open_virtual_port (MIDI_Any (Device), C_Name);
      Free (C_Name);
   end Create_Virtual_Port;

   ----------------
   -- Close_Port --
   ----------------

   procedure Close_Port (Device : MIDI_Out) is
   begin
      rtmidi_close_port (MIDI_Any (Device));
   end Close_Port;

   ------------------
   -- Send_Message --
   ------------------

   procedure Send_Message
     (Device  :     MIDI_Out;
      Message :     System.Storage_Elements.Storage_Array;
      Success : out Boolean)
   is
   begin
      Success := rtmidi_out_send_message (Device,
                                          Message'Address,
                                          Message'Length) = 0;
   end Send_Message;

   ------------------
   -- Send_Message --
   ------------------

   procedure Send_Message (Device  :     MIDI_Out;
                           Message :     System.Address;
                           Len     :     Interfaces.C.int;
                           Success : out Boolean)
   is
   begin
      Success := rtmidi_out_send_message (Device, Message, Len) = 0;
   end Send_Message;

   -----------
   -- Error --
   -----------

   function Error (Device : MIDI_Out) return Boolean
   is (Error (MIDI_Any (Device)));

   -------------------
   -- Error_Message --
   -------------------

   function Error_Message (Device : MIDI_Out) return String
   is (Error_Message (MIDI_Any (Device)));

end RtMIDI;
