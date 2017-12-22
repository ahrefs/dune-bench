open Printf

let dir_rows = ref 1
let dir_cols = ref 1
let mod_rows = ref 1
let mod_cols = ref 1
let num_opens = ref 1
let comment_size = ref 5000


let count n =
  Array.to_list (Array.init n (fun k -> k+1))


let write_directory basedir dir_row dir_col =
  let dirname = sprintf "%s/dir_%d_%d" basedir dir_row dir_col in
  Unix.mkdir dirname 0o777;

  for row = 1 to !mod_rows do
    for col = 1 to !mod_cols do
      let deps =
        if row = 1 then
          if dir_row = 1 then
            []
          else
            List.flatten
              (List.map
                 (fun k ->
                    List.map
                      (fun j ->
                         sprintf "M_%d_%d_%d_%d.f()" (dir_row-1) j !mod_rows k
                      )
                      (count !dir_cols)
                 )
                 (count !num_opens)
              )
        else
          List.map
            (fun k -> sprintf "M_%d_%d_%d_%d.f()" dir_row dir_col (row-1) k)
            (count !num_opens) in

      let deps =
        List.rev ("()" :: (List.rev deps)) in

      let str_deps = String.concat ";\n  " deps in
      let comment = String.make !comment_size 'X' in
      let mod_text = sprintf "(* %s *)
let f() =
  %s
"
          comment
          str_deps in
      let f = open_out
          (sprintf "%s/m_%d_%d_%d_%d.ml" dirname
             dir_row dir_col row col) in
      output_string f mod_text;
      close_out f
    done
  done
let bsconfig = {|
{
    "name": "test",
    "sources" : {
        "dir": "src",
        "subdirs" : true
    }
}
|}
let write basedir =
  let () = Unix.mkdir basedir 0o777 in
  let f = open_out (Filename.concat basedir "bsconfig.json") in
  output_string f bsconfig ;
  let () = close_out f in
  let basedir = (Filename.concat basedir "src") in
  let () = Unix.mkdir basedir 0o777 in
  for row = 1 to !dir_rows do
    for col = 1 to !dir_cols do
      write_directory basedir row col
    done
  done

let () =
  let basedir = ref "." in
  Arg.parse
    [
      "-dir-rows", Arg.Int (fun n -> dir_rows := n),
      "<n>  set number of directory rows";
      "-dir-cols", Arg.Int (fun n -> dir_cols := n),
      "<n>  set number of directory columns";
      "-mod-rows", Arg.Int (fun n -> mod_rows := n),
      "<n>  set number of module rows";
      "-mod-cols", Arg.Int (fun n -> mod_cols := n),
      "<n>  set number of module columns";
      "-num-opens", Arg.Int (fun n -> num_opens := n),
      "<n>  set number of opens in the second directory";
(*       "-n", Arg.Int (fun n -> dir_rows := 2;
                      dir_cols := n;
                      mod_rows := 1;
                      mod_cols := 5000),
      "<n>  set all of -dir-rows, -dir-cols, -mod-rows, -mod-cols to the same value";
 *)      "-comment-size", Arg.Set_int comment_size,
      "<n>  size of the module comment";
    ]
    (fun d ->
       basedir := d
    )
    (sprintf "usage: %s [basedir]" (Filename.basename Sys.argv.(0)));

  write !basedir
