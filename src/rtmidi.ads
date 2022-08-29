with Interfaces.C;

with System;
with System.Storage_Elements;

private with Interfaces.C.Strings;
private with Interfaces.C.Extensions;

package RtMIDI is

   type RtMidiApi is
     (API_UNSPECIFIED,
      API_MACOSX_CORE,
      API_LINUX_ALSA,
      API_UNIX_JACK,
      API_WINDOWS_MM,
      API_RTMIDI_DUMMY,
      API_NUM)
     with Convention => C;

   -- MIDI_In --

   type MIDI_In is limited private;

   function Valid (Device : MIDI_In) return Boolean;

   function Create_Default return MIDI_In;

   function Create (Device_Name      : String;
                    API              : RtMidiApi := API_UNSPECIFIED;
                    Queue_Size_Limit : Natural := 100)
                    return MIDI_In;

   procedure Free (Device : in out MIDI_In)
     with Pre => Valid (Device),
     Post => not Valid (Device);

   function Available_Port_Count (Device : MIDI_In) return Natural
     with Pre => Valid (Device);
   --  Return the number of available MIDI input ports.
   --
   --  This function returns the number of MIDI ports of the selected API.

   function Port_Name (Device     : MIDI_In;
                       Port_Numer : Positive)
                       return String
     with Pre => Valid (Device);

   procedure Open_Port (Device      : MIDI_In;
                        Port_Number : Natural;
                        Name        : String)
     with Pre => Valid (Device);
   --  Connect to an existing MIDI port given by enumeration number.
   --
   --  An optional port number greater than 0 can be specified. Otherwise,
   --  the default or first port found is opened.

   procedure Create_Virtual_Port (Device : MIDI_In;
                                  Name   : String := "RtMIDI Input")
     with Pre => Valid (Device);
   --  Create a virtual input port, with optional name, to allow software
   --  connections (OS X, JACK and ALSA only).
   --
   --  This function creates a virtual MIDI input port to which other software
   --  applications can connect. This type of functionality is currently only
   --  supported by the Macintosh OS-X, any JACK, and Linux ALSA APIs (the
   --  function returns an error for the other APIs).

   procedure Close_Port (Device : MIDI_In)
     with Pre => Valid (Device);
   --  Close an open port, if one exists

   procedure Ignore_Messages (Device : MIDI_In;
                              SysEx  : Boolean;
                              Time   : Boolean;
                              Sense  : Boolean)
     with Pre => Valid (Device);
   --  Specify whether certain MIDI message types should be queued or ignored
   --  during input.
   --
   --  By default, MIDI timing and active sensing messages are ignored during
   --  message input because of their relative high data rates. MIDI sysex
   --  messages are ignored by default as well.Variable values of "true"
   --  imply that the respective message type will be ignored.

   function Get_Message (Device : MIDI_In)
                         return System.Storage_Elements.Storage_Array
     with Pre => Valid (Device);
   --  Return an array with the data bytes for the next available MIDI message
   --  in the input queue.

   function Get_Message (Device  : MIDI_In;
                         Message : System.Address;
                         Size    : not null access Interfaces.C.size_t)
                         return Interfaces.C.double
     with Pre => Valid (Device);
   --  Fill the user-provided array with the data bytes for the next available
   --  MIDI message in the input queue and return the event delta-time in
   --  seconds.
   --
   --  Message:   Must point to a char* that is already allocated.
   --             SYSEX messages maximum size being 1024, a statically
   --             allocated array could
   --             be sufficient.
   --  Size:      Is used to return the size of the message obtained.
   --             Must be set to the size of Message when calling.

   type Input_Callback_C is access procedure
     (Time_Stamp   : Interfaces.C.double;
      Message      : System.Address;
      Message_Size : Interfaces.C.size_t;
      User_Data    : System.Address)
     with Convention => C;

   procedure Set_Callback (Device    : MIDI_In;
                           Callback  : Input_Callback_C;
                           User_Data : System.Address := System.Null_Address)
     with Pre => Valid (Device);
   --  Set a callback function to be invoked for incoming MIDI messages.
   --
   --  The callback function will be called whenever an incoming MIDI message
   --  is received. While not absolutely necessary, it is best to set the
   --  callback function before opening a MIDI port to avoid leaving some
   --  messages in the queue.
   --
   --  callback: A callback function must be given. If Callback is null,
   --            previously set callback is cancelled.
   --  userData: Optionally, a pointer to additional data can be
   --            passed to the callback function whenever it is called.
   --

   function Error (Device : MIDI_In) return Boolean
     with Pre => Valid (Device);
   --  True when the last function call was not OK

   function Error_Message (Device : MIDI_In) return String
     with Pre => Valid (Device) and then Error (Device);
   --  Return an error message when the last function call was not OK

   -- MIDI_Out --

   type MIDI_Out is limited private;

   function Valid (Device : MIDI_Out) return Boolean;

   function Create_Default return MIDI_Out;

   function Create (Device_Name : String;
                    API         : RtMidiApi := API_UNSPECIFIED)
                    return MIDI_Out;

   procedure Free (Device : in out MIDI_Out)
     with Pre => Valid (Device),
         Post => not Valid (Device);

   function Available_Port_Count (Device : MIDI_Out) return Natural
     with Pre => Valid (Device);
   --  Return the number of available MIDI Output ports.
   --
   --  This function returns the number of MIDI ports of the selected API.

   function Port_Name (Device     : MIDI_Out;
                       Port_Numer : Positive)
                       return String
     with Pre => Valid (Device);

   procedure Open_Port (Device      : MIDI_Out;
                        Port_Number : Natural;
                        Name        : String)
     with Pre => Valid (Device);
   --  Connect to an existing MIDI port given by enumeration number.
   --
   --  An optional port number greater than 0 can be specified. Otherwise,
   --  the default or first port found is opened.

   procedure Create_Virtual_Port (Device : MIDI_Out;
                                  Name   : String := "RtMidi Output")
     with Pre => Valid (Device);
   --  Create a virtual output port, with optional name, to allow software
   --  connections (OS X, JACK and ALSA only).
   --
   --  This function creates a virtual MIDI output port to which other
   --  software applications can connect. This type of functionality is
   --  currently only supported by the Macintosh OS-X, any JACK, and Linux
   --  ALSA APIs (the function returns an error for the other APIs).

   procedure Close_Port (Device : MIDI_Out)
     with Pre => Valid (Device);
   --  Close an open port, if one exists

   procedure Send_Message
     (Device  :     MIDI_Out;
      Message :     System.Storage_Elements.Storage_Array;
      Success : out Boolean)
     with Pre => Valid (Device);
   --  Immediately send a single message out an open MIDI output port.

   procedure Send_Message (Device  :     MIDI_Out;
                           Message :     System.Address;
                           Len     :     Interfaces.C.int;
                           Success : out Boolean)
     with Pre => Valid (Device);
   --  Immediately send a single message out an open MIDI output port.

   function Error (Device : MIDI_Out) return Boolean
     with Pre => Valid (Device);
   --  True when the last function call was not OK

   function Error_Message (Device : MIDI_Out) return String
     with Pre => Valid (Device) and then Error (Device);
   --  Return an error message when the last function call was not OK

private

   type MIDI_Any is new System.Address;

   function Valid (Device : MIDI_Any) return Boolean
   is (Device /= MIDI_Any (System.Null_Address));

   function Error (Device : MIDI_Any) return Boolean
     with Pre => Valid (Device);
   --  True when the last function call was not OK

   function Error_Message (Device : MIDI_Any) return String
     with Pre => Valid (Device) and then Error (Device);
   --  Return an error message when the last function call was not OK

   function Available_Port_Count (Device : MIDI_Any) return Natural;

   function Port_Name (Device     : MIDI_Any;
                       Port_Numer : Positive)
                       return String;

   type MIDI_In is new System.Address;

   function Valid (Device : MIDI_In) return Boolean
   is (Device /= MIDI_In (System.Null_Address));

   type MIDI_Out is new System.Address;

   function Valid (Device : MIDI_Out) return Boolean
   is (Device /= MIDI_Out (System.Null_Address));

      --! True when the last function call was OK.
   --! If an error occured (ok != true), set to an error message.
   --! \brief Typedef for a generic RtMidi pointer.
   subtype RtMidiPtr is MIDI_Any;  -- /usr/include/rtmidi/rtmidi_c.h:52

   --! \brief Typedef for a generic RtMidiIn pointer.
   subtype RtMidiInPtr is MIDI_In;  -- /usr/include/rtmidi/rtmidi_c.h:55

   --! \brief Typedef for a generic RtMidiOut pointer.
   subtype RtMidiOutPtr is MIDI_Out;

   --! \brief MIDI API specifier arguments.  See \ref RtMidi::Api.

   --!< Search for a working compiled API.
   --!< Macintosh OS-X CoreMIDI API.
   --!< The Advanced Linux Sound Architecture API.
   --!< The Jack Low-Latency MIDI Server API.
   --!< The Microsoft Multimedia MIDI API.
   --!< A compilable but non-functional API.
   --!< Number of values in this enum.
   --! \brief Defined RtMidiError types. See \ref RtMidiError::Type.
   type RtMidiErrorType is
     (RTMIDI_ERROR_WARNING,
      RTMIDI_ERROR_DEBUG_WARNING,
      RTMIDI_ERROR_UNSPECIFIED,
      RTMIDI_ERROR_NO_DEVICES_FOUND,
      RTMIDI_ERROR_INVALID_DEVICE,
      RTMIDI_ERROR_MEMORY_ERROR,
      RTMIDI_ERROR_INVALID_PARAMETER,
      RTMIDI_ERROR_INVALID_USE,
      RTMIDI_ERROR_DRIVER_ERROR,
      RTMIDI_ERROR_SYSTEM_ERROR,
      RTMIDI_ERROR_THREAD_ERROR)
     with Convention => C;  -- /usr/include/rtmidi/rtmidi_c.h:72

   --!< A non-critical error.
   --!< A non-critical error which might be useful for debugging.
   --!< The default, unspecified error type.
   --!< No devices found on system.
   --!< An invalid device ID was specified.
   --!< An error occured during memory allocation.
   --!< An invalid parameter was specified to a function.
   --!< The function was called incorrectly.
   --!< A system driver error occured.
   --!< A system error occured.
   --!< A thread error occured.

   --  RtMidi API
   --! \brief Determine the available compiled MIDI APIs.
   --  *
   --  * If the given `apis` parameter is null, returns the number of
   --   available APIs.
   --  * Otherwise, fill the given apis array with the RtMidi::Api values.
   --  *
   --  * \param apis  An array or a null value.
   --  * \param apis_size  Number of elements pointed to by apis
   --  * \return number of items needed for apis array if apis==NULL, or
   --  *         number of items written to apis array otherwise.  A negative
   --  *         return value indicates an error.
   --  *
   --  * See \ref RtMidi::getCompiledApi().
   --

   function rtmidi_get_compiled_api (apis : access RtMidiApi;
                                     apis_size : Interfaces.C.unsigned)
                                     return Interfaces.C.int
   --  /usr/include/rtmidi/rtmidi_c.h:113
     with Import => True,
     Convention => C,
     External_Name => "rtmidi_get_compiled_api";

   --! \brief Return the name of a specified compiled MIDI API.
   --! See \ref RtMidi::getApiName().
   function rtmidi_api_name (api : RtMidiApi)
                             return Interfaces.C.Strings.chars_ptr
   --  /usr/include/rtmidi/rtmidi_c.h:117
     with Import => True,
     Convention => C,
     External_Name => "rtmidi_api_name";

   --! \brief Return the display name of a specified compiled MIDI API.
   --! See \ref RtMidi::getApiDisplayName().
   function rtmidi_api_display_name (api : RtMidiApi)
                                     return Interfaces.C.Strings.chars_ptr
   --  /usr/include/rtmidi/rtmidi_c.h:121
     with Import => True,
     Convention => C,
     External_Name => "rtmidi_api_display_name";

   --! \brief Return the compiled MIDI API having the given name.
   --! See \ref RtMidi::getCompiledApiByName().
   function rtmidi_compiled_api_by_name
     (name : Interfaces.C.Strings.chars_ptr) return RtMidiApi
   --  /usr/include/rtmidi/rtmidi_c.h:125
     with Import => True,
     Convention => C,
     External_Name => "rtmidi_compiled_api_by_name";

   --! \internal Report an error.
   procedure rtmidi_error (c_type : RtMidiErrorType;
                           errorString : Interfaces.C.Strings.chars_ptr)
     -- /usr/include/rtmidi/rtmidi_c.h:128
     with Import => True,
     Convention => C,
     External_Name => "rtmidi_error";

   --! \brief Open a MIDI port.
   --  *
   --  * \param port      Must be greater than 0
   --  * \param portName  Name for the application port.
   --  *
   --  * See RtMidi::openPort().
   --

   procedure rtmidi_open_port
     (device : RtMidiPtr;
      portNumber : Interfaces.C.unsigned;
      portName : Interfaces.C.Strings.chars_ptr)
     -- /usr/include/rtmidi/rtmidi_c.h:137
     with Import => True,
     Convention => C,
     External_Name => "rtmidi_open_port";

   --! \brief Creates a virtual MIDI port to which other software
   --   applications can
   --  * connect.
   --  *
   --  * \param portName  Name for the application port.
   --  *
   --  * See RtMidi::openVirtualPort().
   --

   procedure rtmidi_open_virtual_port
     (device : RtMidiPtr;
      portName : Interfaces.C.Strings.chars_ptr)
     -- /usr/include/rtmidi/rtmidi_c.h:146
     with Import => True,
     Convention => C,
     External_Name => "rtmidi_open_virtual_port";

   --! \brief Close a MIDI connection.
   --  * See RtMidi::closePort().
   --

   procedure rtmidi_close_port (device : RtMidiPtr)
     -- /usr/include/rtmidi/rtmidi_c.h:151
     with Import => True,
     Convention => C,
     External_Name => "rtmidi_close_port";

   --! \brief Return the number of available MIDI ports.
   --  * See RtMidi::getPortCount().

   function rtmidi_get_port_count (device : RtMidiPtr)
                                   return Interfaces.C.unsigned
   --  /usr/include/rtmidi/rtmidi_c.h:156
     with Import => True,
     Convention => C,
     External_Name => "rtmidi_get_port_count";

   --! \brief Access a string identifier for the specified MIDI input port
   --   number.
   --  *
   --  * To prevent memory leaks a char buffer must be passed to this
   --    function.
   --  * NULL can be passed as bufOut parameter, and that will write the
   --    required buffer length in the bufLen.
   --  *
   --  * See RtMidi::getPortName().
   --

   function rtmidi_get_port_name
     (device : RtMidiPtr;
      portNumber : Interfaces.C.unsigned;
      bufOut : Interfaces.C.Strings.chars_ptr;
      bufLen : access Interfaces.C.int)
      return Interfaces.C.int
   --  /usr/include/rtmidi/rtmidi_c.h:165
     with Import => True,
     Convention => C,
     External_Name => "rtmidi_get_port_name";

   --  RtMidiIn API
   --! \brief Create a default RtMidiInPtr value, with no initialization.
   function rtmidi_in_create_default return RtMidiInPtr
   --  /usr/include/rtmidi/rtmidi_c.h:170
     with Import => True,
     Convention => C,
     External_Name => "rtmidi_in_create_default";

   --! \brief Create a  RtMidiInPtr value, with given api, clientName
   --  and queueSizeLimit.
   --
   --  \param api            An optional API id can be specified.
   --  \param clientName     An optional client name can be specified. This
   --                        will be used to group the ports that are created
   --                        by the application.
   --  \param queueSizeLimit An optional size of the MIDI input queue can be
   --                        specified.
   --
   --   See RtMidiIn::RtMidiIn().
   --

   function rtmidi_in_create
     (api : RtMidiApi;
      clientName : Interfaces.C.Strings.chars_ptr;
      queueSizeLimit : Interfaces.C.unsigned) return RtMidiInPtr
   --  /usr/include/rtmidi/rtmidi_c.h:183
     with Import => True,
     Convention => C,
     External_Name => "rtmidi_in_create";

   --! \brief Free the given RtMidiInPtr.
   procedure rtmidi_in_free (device : RtMidiInPtr)
     --  /usr/include/rtmidi/rtmidi_c.h:186
     with Import => True,
     Convention => C,
     External_Name => "rtmidi_in_free";

   --! \brief Returns the MIDI API specifier for the given instance of
   --  RtMidiIn.
   --! See \ref RtMidiIn::getCurrentApi().
   function rtmidi_in_get_current_api (device : RtMidiPtr) return RtMidiApi
   --  /usr/include/rtmidi/rtmidi_c.h:190
     with Import => True,
     Convention => C,
     External_Name => "rtmidi_in_get_current_api";

   --! \brief Set a callback function to be invoked for incoming MIDI messages.
   --! See \ref RtMidiIn::setCallback().
   procedure rtmidi_in_set_callback
     (device : RtMidiInPtr;
      callback : Input_Callback_C;
      userData : System.Address)  -- /usr/include/rtmidi/rtmidi_c.h:194
     with Import => True,
     Convention => C,
     External_Name => "rtmidi_in_set_callback";

   --! \brief Cancel use of the current callback function (if one exists).
   --! See \ref RtMidiIn::cancelCallback().
   procedure rtmidi_in_cancel_callback (device : RtMidiInPtr)
     --  /usr/include/rtmidi/rtmidi_c.h:198
     with Import => True,
     Convention => C,
     External_Name => "rtmidi_in_cancel_callback";

   --! \brief Specify whether certain MIDI message types should be queued
   --  or ignored during input.
   --! See \ref RtMidiIn::ignoreTypes().
   procedure rtmidi_in_ignore_types
     (device : RtMidiInPtr;
      midiSysex : Interfaces.C.Extensions.bool;
      midiTime : Interfaces.C.Extensions.bool;
      midiSense : Interfaces.C.Extensions.bool)
     --  /usr/include/rtmidi/rtmidi_c.h:202
     with Import => True,
     Convention => C,
     External_Name => "rtmidi_in_ignore_types";

   --! Fill the user-provided array with the data bytes for the next available
   --  * MIDI message in the input queue and return the event delta-time in
   --    seconds.
   --  *
   --  * \param message   Must point to a char* that is already allocated.
   --  *                  SYSEX messages maximum size being 1024, a statically
   --  *                  allocated array could
   --  *                  be sufficient.
   --  * \param size      Is used to return the size of the message obtained.
   --  *                  Must be set to the size of \ref message when calling.
   --  *
   --  * See RtMidiIn::getMessage().
   --

   function rtmidi_in_get_message
     (device : RtMidiInPtr;
      message : System.Address;
      size : access Interfaces.C.size_t) return Interfaces.C.double
   --  /usr/include/rtmidi/rtmidi_c.h:216
     with Import => True,
     Convention => C,
     External_Name => "rtmidi_in_get_message";

   --  RtMidiOut API
   --! \brief Create a default RtMidiInPtr value, with no initialization.
   function rtmidi_out_create_default return RtMidiOutPtr
   --  /usr/include/rtmidi/rtmidi_c.h:221
     with Import => True,
     Convention => C,
     External_Name => "rtmidi_out_create_default";

   --! \brief Create a RtMidiOutPtr value, with given and clientName.
   --
   --  \param api            An optional API id can be specified.
   --  \param clientName     An optional client name can be specified. This
   --                        will be used to group the ports that are created
   --                        by the application.
   --
   --  See RtMidiOut::RtMidiOut().
   --

   function rtmidi_out_create (api : RtMidiApi;
                               clientName : Interfaces.C.Strings.chars_ptr)
                               return RtMidiOutPtr
   --  /usr/include/rtmidi/rtmidi_c.h:232
     with Import => True,
     Convention => C,
     External_Name => "rtmidi_out_create";

   --! \brief Free the given RtMidiOutPtr.
   procedure rtmidi_out_free (device : RtMidiOutPtr)
     --  /usr/include/rtmidi/rtmidi_c.h:235
     with Import => True,
     Convention => C,
     External_Name => "rtmidi_out_free";

   --! \brief Returns the MIDI API specifier for the given instance of
   --   RtMidiOut.
   --! See \ref RtMidiOut::getCurrentApi().
   function rtmidi_out_get_current_api (device : RtMidiPtr)
                                        return RtMidiApi
   --  /usr/include/rtmidi/rtmidi_c.h:239
     with Import => True,
     Convention => C,
     External_Name => "rtmidi_out_get_current_api";

   --! \brief Immediately send a single message out an open MIDI output port.
   --! See \ref RtMidiOut::sendMessage().
   function rtmidi_out_send_message
     (device : RtMidiOutPtr;
      message : System.Address;
      length : Interfaces.C.int)
      return Interfaces.C.int  -- /usr/include/rtmidi/rtmidi_c.h:243
     with Import => True,
     Convention => C,
     External_Name => "rtmidi_out_send_message";

   --! }@

end RtMIDI;
