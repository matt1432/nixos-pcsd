{
  backports = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0dbjl5ilyzlhl4p60pq41kdy4j8bg21f4m1vccawlh1wvhr8sacl";
      type = "gem";
    };
    version = "3.25.3";
  };
  base64 = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0yx9yn47a8lkfcjmigk79fykxvr80r4m1i35q82sxzynpbm7lcr7";
      type = "gem";
    };
    version = "0.3.0";
  };
  childprocess = {
    dependencies = ["logger"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1v5nalaarxnfdm6rxb7q6fmc6nx097jd630ax6h9ch7xw95li3cs";
      type = "gem";
    };
    version = "5.1.0";
  };
  ethon = {
    dependencies = ["ffi" "logger"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1cpwds6mpija1bwh8p89fqa993llssvi81w5ic3cnj04yg4sz65m";
      type = "gem";
    };
    version = "0.18.0";
  };
  ffi = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0k1xaqw2jk13q3ss7cnyvkp8fzp75dk4kazysrxgfd1rpgvkk7qf";
      type = "gem";
    };
    version = "1.17.3";
  };
  json = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "01fmiz052cvnxgdnhb3qwcy88xbv7l3liz0fkvs5qgqqwjp0c1di";
      type = "gem";
    };
    version = "2.18.0";
  };
  logger = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "00q2zznygpbls8asz5knjvvj2brr3ghmqxgr83xnrdj4rk3xwvhr";
      type = "gem";
    };
    version = "1.7.0";
  };
  mustermann = {
    dependencies = ["ruby2_keywords"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "08ma2fmxlm6i7lih4mc3har2fzsbj1pl4hhva65kljf6nfvdryl5";
      type = "gem";
    };
    version = "3.0.4";
  };
  nio4r = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "18fwy5yqnvgixq3cn0h63lm8jaxsjjxkmj8rhiv8wpzv9271d43c";
      type = "gem";
    };
    version = "2.7.5";
  };
  power_assert = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "00s1sfjak8w3f12g66ldb61xjavr5p2wvkflziiyhx6c2rkqgscc";
      type = "gem";
    };
    version = "3.0.1";
  };
  puma = {
    dependencies = ["nio4r"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1pa9zpr51kqnsq549p6apvnr95s9flx6bnwqii24s8jg2b5i0p74";
      type = "gem";
    };
    version = "7.1.0";
  };
  rack = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1xmnrk076sqymilydqgyzhkma3hgqhcv8xhy7ks479l2a3vvcx2x";
      type = "gem";
    };
    version = "3.2.4";
  };
  rack-protection = {
    dependencies = ["base64" "logger" "rack"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1b4bamcbpk29i7jvly3i7ayfj69yc1g03gm4s7jgamccvx12hvng";
      type = "gem";
    };
    version = "4.2.1";
  };
  rack-session = {
    dependencies = ["base64" "rack"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1sg4laz2qmllxh1c5sqlj9n1r7scdn08p3m4b0zmhjvyx9yw0v8b";
      type = "gem";
    };
    version = "2.1.1";
  };
  rack-test = {
    dependencies = ["rack"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0qy4ylhcfdn65a5mz2hly7g9vl0g13p5a0rmm6sc0sih5ilkcnh0";
      type = "gem";
    };
    version = "2.2.0";
  };
  rackup = {
    dependencies = ["rack"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0s48d2a0z5f0cg4npvzznf933vipi6j7gmk16yc913kpadkw4ybc";
      type = "gem";
    };
    version = "2.3.1";
  };
  rexml = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0hninnbvqd2pn40h863lbrn9p11gvdxp928izkag5ysx8b1s5q0r";
      type = "gem";
    };
    version = "3.4.4";
  };
  ruby2_keywords = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1vz322p8n39hz3b4a9gkmz9y7a5jaz41zrm2ywf31dvkqm03glgz";
      type = "gem";
    };
    version = "0.0.5";
  };
  sinatra = {
    dependencies = ["logger" "mustermann" "rack" "rack-protection" "rack-session" "tilt"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "103h6wjpcqp3i034hi44za2v365yz7qk9s5df8lmasq43nqvkbmp";
      type = "gem";
    };
    version = "4.2.1";
  };
  test-unit = {
    dependencies = ["power_assert"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0i8ymnz0cnxxkk7g9z2dsnwh411r4i36q5a6k7pnp8ch0vzxb29w";
      type = "gem";
    };
    version = "3.7.7";
  };
  tilt = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1cvaikq1dcbfl008i16c1pi1gmdax7vfkvmhch64jdkakyk9nnqd";
      type = "gem";
    };
    version = "2.7.0";
  };
}
