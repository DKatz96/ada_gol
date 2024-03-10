with Text_IO; use Text_IO;
with Ada.Command_Line; 
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Characters.Latin_1; use Ada.Characters.Latin_1;

procedure gol is
	package CLI renames Ada.Command_Line;

	type t_board_width  is mod 80;
	type t_board_height is mod 40;

	type t_cell is (cell_alive, cell_dead);
	type t_board is array (t_board_height, t_board_width) of t_cell; 
	type t_nb_boards is mod 2;
	type t_board_array is array (t_nb_boards) of t_board;

	boards : t_board_array :=  (others => (others => (others => cell_dead)));
	active_board : t_nb_boards := 0;
	
	procedure init_board (board : in out t_board; f_path : in string) is
		F : File_Type;
		y : t_board_height := 0;
	begin
		Open(F, In_File, f_path);
		while not End_Of_File(F) loop
			declare
				x : t_board_width := 0;
				line : string := Get_Line(F);
			begin
				for c of line loop
					board(y,x) := (if c = 'O' then cell_alive else cell_dead);
					x := x+1;	
				end loop;
			end;
			y := y+1;
		end loop;
		Close(F);
	end init_board;

	procedure draw_board (board : in t_board) is 
	begin
		for height in t_board_height'range loop
			declare
				line : String (1..(Integer(t_board_width'last)) + 1) := (others => ' ');
			begin	
				for width in t_board_width'range loop
					line(Integer(width) + 1) := 
						(case board(height, width) is
						 when cell_alive => '#',
  						 when cell_dead  => '.');
				end loop;
				Put_Line(line);
			end;
		end loop;
	end draw_board;

	function get_nb_of_alive_neighbors (board : in t_board; x : in t_board_width; y : in t_board_height) return Integer is
		nb_neighbors_alive : Integer := 0;
	begin
		for width in t_board_width range 0..2 loop
			for height in t_board_height range 0..2 loop
				if not ((height = 1) and (width = 1)) then
					declare
						t_x : t_board_width  := x + width - 1;
						t_y : t_board_height := y + height - 1;
					begin
						if board(t_y, t_x) = cell_alive then
							nb_neighbors_alive := nb_neighbors_alive + 1;
						end if;
					end;
				end if;
			end loop;
		end loop;
		return nb_neighbors_alive;
	end get_nb_of_alive_neighbors;

	procedure calculate_next_state (prev : in t_board; next : in out t_board) is
	begin
		next := (others => (others => cell_dead));
		for height in t_board_height'range loop
			for width in t_board_width'range loop
				next(height, width) := (case get_nb_of_alive_neighbors(prev, width, height) is
						  	when 2 => (if prev(height, width) = cell_alive then cell_alive else cell_dead),
							when 3 => cell_alive,
							when others => cell_dead);
			end loop;
		end loop;
		
	end calculate_next_state;	
begin
	if (CLI.Argument_Count /= 1) then
		Put_Line(Standard_Error, "requires 1 arguments: fpath");
		return;
	end if;

	init_board(boards(0), CLI.Argument(Number => 1));
	draw_board(boards(0));
	Put_Line(ESC & "[41A");
	while true loop
		calculate_next_state(boards(active_board), boards(active_board+1));
		draw_board(boards(active_board+1));
		active_board := active_board+1;
		Put_Line(ESC & "[41A");
		delay 0.1;
	end loop;
end gol;
