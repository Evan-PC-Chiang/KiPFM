% This script specifies the faults to include in your inversion 
% by adding their names to the list.
%
% NOTE: Each fault name must exactly match the corresponding 
% file name in /fault_mesh_files.

namelist = [
    {'CRF'              }
    {'Changhua'         }
    {'Chaochou'         }
    {'Chelungpu'        }
    {'Chishan'          }
    {'Chiuchiungkeng'   }
    {'Chungchou'        }
    {'Chushiang'        }
    {'East_Miaoli'      }
    {'Fengshan'         }
    {'Fengshan_River'   }
    {'Fengshan_hills'   }
    {'Gukeng'           }
    {'Hengchun'         }
    {'Hengchun_offshore'}
    {'Houchiali'        }
    {'Hsiaokangshan'    }
    {'Hsincheng'        }
    {'Hsinchu'          }
    {'Hsinchu_frontal'  }
    {'Hsinhua'          }
    {'Hukou'            }
    {'Kaoping'          }
    {'LVF'              }
    {'Longchuan'        }
    {'Luyeh'            }
    {'Meishan'          }
    {'Miaoli_frontal'   }
    {'Milun'            }
    {'Muchiliao'        }
    {'Northern_Ilan'    }
    {'Sanyi'            }
    {'Shanchiao'        }
    {'Shihtan'          }
    {'Shuanglienpo'     }
    {'Southern_Ilan'    }
    {'Taimali'          }
    {'Tamaopu'          }
    {'Touhuanping'      }
    {'Tunglo'           }
    {'Tuntzuchiao'      }
    {'Yangmei'          }
    {'Youchang'         }
    {'east_offshore'    }
    {'NCRF'             }
    {'green_island_left'}
    {'N_oki'            }
    {'S_oki'            }
    {'ryukyu'           }
    {'Tainan_frontal'   }
    {'Chiayi_frontal'   }];


save("namelist.mat", "namelist")