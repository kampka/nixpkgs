{ lib }: rec {
  /*
  Every entry in this file represents a format for configuration files of
  programs, used for `settings` options. Each entry has to look as follows:

    <format> = {

      # The module system type most suitable for representing such a format
      type = ...;

      # A function taking an instance of such a type and turning it into a string
      generate = ...;

    }
  */

  json = {
    type = with lib.types; let
      value = nullOr (oneOf [
        bool
        int
        float
        str
        (attrsOf value)
        (listOf value)
      ]) // {
        description = "JSON value";
      };
    in value;
    generate = builtins.toJSON;
  };

  # YAML has been a strict superset of JSON since 1.2
  yaml = json // {
    type = json.type // { 
      description = "YAML value";
    };
  };

  ini = {
    type = with lib.types; let
      iniAtom = nullOr (oneOf [
        bool
        int
        float
        str
      ]);
    in attrsOf (attrsOf iniAtom);
    generate = lib.generators.toINI {};
  };
}
