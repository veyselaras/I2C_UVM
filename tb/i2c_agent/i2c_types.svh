`ifndef I2C_TYPES_SVH
	`define I2C_TYPES_SVH

typedef virtual i2c_if i2c_vif;

typedef enum bit{I2C_WRITE = 0, I2C_READ = 1} i2c_dir_e;

typedef enum bit{I2C_ACK = 0, I2C_NACK = 1} i2c_ack_e;

`endif