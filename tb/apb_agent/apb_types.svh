`ifndef APB_TYPES_SVH
	`define APB_TYPES_SVH

typedef virtual apb_if apb_vif; 

typedef enum bit{APB_READ = 0, APB_WRITE = 1} apb_dir_e;

typedef enum bit{APB_DONE = 0, APB_ERR = 1} apb_err_e;

`endif