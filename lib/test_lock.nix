{ lock
, pkgs
, lib
, ...
}: {
  inherit (builtins) removeAttrs;

  mkOverlay = {
    testWrongMetadataVersion = {
      expr = lock.mkOverlay {
        metadata = {
          lock_version = "3.0";
        };
      };
      expectedError.type = "AssertionError";
    };
  };

  mkPackage =
    let
      callPackage = pkg:
        let
          drv = pkgs.python311.pkgs.callPackage pkg { };

          # Remove stuff we can't assert equality for easily
          cleaned = removeAttrs drv [ "override" "overrideDerivation" ];
        in
        cleaned
        // {
          # Just extract names of dependencies for equality checking
          propagatedBuildInputs = map (drv: drv.pname) cleaned.propagatedBuildInputs;
        };
    in
    {
      testSimple = {
        expr = callPackage (lock.mkPackage {
          files = [
            {
              file = "Arpeggio-2.0.0-py2.py3-none-any.whl";
              hash = "sha256:448e332deb0e9ccd04046f1c6c14529d197f41bc2fdb3931e43fc209042fbdd3";
            }
            {
              file = "Arpeggio-2.0.0.tar.gz";
              hash = "sha256:d6b03839019bb8a68785f9292ee6a36b1954eb84b925b84a6b8a5e1e26d3ed3d";
            }
          ];
          name = "arpeggio";
          summary = "Packrat parser interpreter";
          version = "2.0.0";
        });
        expected = {
          meta = {
            broken = false;
            description = "Packrat parser interpreter";
          };
          pname = "arpeggio";
          propagatedBuildInputs = [ ];
          version = "2.0.0";
          src = null;
        };
      };

      testWithDependencies = {
        expr = callPackage (lock.mkPackage {
          dependencies = [
            "python-dateutil>=2.7.0"
            "typing-extensions; python_version < \"3.8\""
          ];
          files = [
            {
              file = "arrow-1.2.3-py3-none-any.whl";
              hash = "sha256:5a49ab92e3b7b71d96cd6bfcc4df14efefc9dfa96ea19045815914a6ab6b1fe2";
            }
            {
              file = "arrow-1.2.3.tar.gz";
              hash = "sha256:3934b30ca1b9f292376d9db15b19446088d12ec58629bc3f0da28fd55fb633a1";
            }
          ];
          name = "arrow";
          requires_python = ">=3.6";
          summary = "Better dates & times for Python";
          version = "1.2.3";
        });
        expected = {
          meta = {
            broken = false;
            description = "Better dates & times for Python";
          };
          pname = "arrow";
          propagatedBuildInputs = [ "python-dateutil" ];
          version = "1.2.3";
          src = null;
        };
      };

      testWithDependenciesOptionals = {
        expr = callPackage (lock.mkPackage {
          dependencies = [
            "cachecontrol[filecache]"
          ];
          files = [
            {
              file = "arrow-1.2.3.tar.gz";
              hash = "sha256:3934b30ca1b9f292376d9db15b19446088d12ec58629bc3f0da28fd55fb633a1";
            }
          ];
          name = "dummy";
          requires_python = ">=3.6";
          summary = "Dummy test package";
          version = "1.2.3";
        });
        expected = {
          meta = {
            broken = false;
            description = "Dummy test package";
          };
          pname = "dummy";
          propagatedBuildInputs = [ "cachecontrol" "filelock" ];
          version = "1.2.3";
          src = null;
        };
      };
    };

  partitionFiles = {
    testSimple = {
      expr = lock.partitionFiles (builtins.head (lib.importTOML ./fixtures/trivial/pdm.lock).package).files;
      expected = {
        others = [ ];
        sdists = [
          {
            file = "Arpeggio-2.0.2.tar.gz";
            hash = "sha256:c790b2b06e226d2dd468e4fbfb5b7f506cec66416031fde1441cf1de2a0ba700";
          }
        ];
        wheels = [
          {
            file = "Arpeggio-2.0.2-py2.py3-none-any.whl";
            hash = "sha256:f7c8ae4f4056a89e020c24c7202ac8df3e2bc84e416746f20b0da35bb1de0250";
          }
        ];
      };
    };
  };
}