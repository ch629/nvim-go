(import_declaration 
    (import_spec_list 
        (import_spec path: 
            (interpreted_string_literal) @definition.import_path)))

(import_declaration 
    (import_spec_list 
        (import_spec name: 
            (package_identifier) @definition.pkg_identifier)))
