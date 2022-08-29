with AAA.Strings;
with Ada.Text_IO; use Ada.Text_IO;
with System.Storage_Elements; use System.Storage_Elements;

with RtMIDI; use RtMIDI;

procedure Tests is
   Test_Out : MIDI_Out := Create ("Test rtMIDI Out");
   Test_In : MIDI_In := Create ("Test rtMIDI In");

   Port_Found : Integer := -1;
begin

   Create_Virtual_Port (Test_Out, "Test output virt port");
   if Error (Test_Out) then
      raise Program_Error
        with "RtMIDI Error: '" & Error_Message (Test_Out) & "'";
   end if;

   Put_Line ("Available_Port_Count Input:" &
               Available_Port_Count (Test_In)'Img);
   for X in 1 .. Available_Port_Count (Test_In) loop
      declare
         Name : constant String := Port_Name (Test_In, X);
      begin
         if AAA.Strings.Has_Prefix (Name, "Test rtMIDI Out") then
            Port_Found := X;
            exit;
         end if;
      end;
   end loop;

   if Port_Found <= 0 then
      Put_Line ("Cannot find the port we just openned. Use default one...");
      Port_Found := 0;
   end if;

   Open_Port (Test_In, Port_Found, "Test input virt port");

   if Error (Test_In) then
      raise Program_Error
        with "RtMIDI Error: '" & Error_Message (Test_In) & "'";
   end if;

   declare
      Success : Boolean;
   begin
      Send_Message (Test_Out, (16#90#, 16#3C#, 16#40#), Success);
      if not Success then
         raise Program_Error
           with "RtMIDI Error: '" & Error_Message (Test_In) & "'";
      end if;

      delay 0.5;

      declare
         Message : constant Storage_Array := Get_Message (Test_In);
         package MIO is new Ada.Text_IO.Modular_IO (Storage_Element);
      begin
         Put ("Got message: '");
         for Elt of Message loop
            MIO.Put (Elt, Base => 16);
         end loop;
         Put_Line ("'");
      end;

   end;

   Close_Port (Test_Out);
   Close_Port (Test_In);

   Free (Test_Out);
   Free (Test_In);
end Tests;
