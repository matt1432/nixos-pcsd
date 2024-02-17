# NixOS pcsd

This is a Nix flake containing the package [pcs](https://github.com/ClusterLabs/pcs)
and a module for it that allows you to manage a Pacemaker cluster
declaratively in nix code.

## Docs

You can read about the options this module exposes here: <https://matt1432.github.io/nixos-pcsd/all/>

## Usage

In your `flake.nix` inputs:

```nix
...
pcsd = {
  # This way of declaring inputs is way cleaner IMO
  type = "github";
  owner = "matt1432";
  repo = "nixos-pcsd";

  # Here is the classic one
  # url = "github:matt1432/nixos-pcsd";

  # You can uncomment this line, but I've had a lot of issues (they're fixed now)
  # with latest unstable, so I recommend not changing this flake's nixpkgs
  # inputs.nixpkgs.follows = "nixpkgs";
};
...
```

Before enabling this module, it is very important to know that it will manage
`services.pacemaker` and `services.corosync` for you. Any of their settings
could be replaced by the ones you declare in `services.pcsd`.

In your server config, this would be the most barebones settings:

```nix
{pcsd, ...}: {
  imports = [pcsd.nixosModules.default];

  services.pcsd = {
    enable = true;
    enableBinaryCache = true;

    # I highly recommend using sops-nix or agenix for these settings
    corosyncKeyFile = builtins.toFile "keyfile" "some128charLongText";
    clusterUserPasswordFile = builtins.toFile "password" "somePassword";

    nodes = [
      {
        name = "this Machine's Hostname";
        nodeid = 1;
        ring_addrs = [
          # This is where your machine's local ips go
          "192.168.0.255"
        ];
      }

      # the other nodes of your cluster go here
    ];
  };
}
```

You can also take a look at my [pcsd setup](https://git.nelim.org/matt1432/nixos-configs/src/branch/master/devices/cluster/modules/pcsd.nix)
to see more options and a real world example.

## Credits

- [ClusterLabs](https://github.com/ClusterLabs) for the software used to
configure the cluster:
  - <https://github.com/ClusterLabs/pcs>
- [Mitchty](https://github.com/mitchty) for sharing the only method I've found
to manage pacemaker on NixOS:
  - <https://github.com/mitchty/nix/blob/master/modules/nixos/cluster.nix>
  - <https://github.com/NixOS/nixpkgs/pull/208298>
