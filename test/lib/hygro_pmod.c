/************************************************************************/
/*																		*/
/*	HYGROI2C.cpp		--		Definition for HYGROI2C library 	    */
/*																		*/
/************************************************************************/
/*	Author:		Arthur Brown											*/
/*	Copyright 2017, Digilent Inc.										*/
/************************************************************************/
/*  File Description:													*/
/*		This file defines functions for HYGROI2C						*/
/*																		*/
/************************************************************************/
/*  Revision History:													*/
/*																		*/
/*	01/30/2017(ArtVVB): created											*/
/*																		*/
/************************************************************************/


/* ------------------------------------------------------------ */
/*				Include File Definitions						*/
/* ------------------------------------------------------------ */

#include <stdint.h>
#include <stdbool.h>
#include <rv32i.h>
/* ------------------------------------------------------------ */
/*				Procedure Definitions							*/
/* ------------------------------------------------------------ */



/* ------------------------------------------------------------ */
/*        HYGROI2C::writeRegI2C
**
**        Synopsis:
**				writeRegI2C(bConfig);
**
**        Parameters:
**				uint8_t bReg - the register address to be written to
**				uint16_t bVal - the bytes to be written
**
**        Return Values:
**                void 
**
**        Errors:
**			none
**
**        Description:
**			This function writes to a register over I2C. 
**
*/
uint8_t hygroi2c_writeRegI2C(uint8_t bReg, uint16_t bVal)
{   
    uint8_t ack;
    ack = i2c_write_address(HYGROI2C_I2C_ADDR<<1); // start i2c by writing slave address (returns slave ack)
    i2c_write_byte(bReg); // write to slave (returns slave ack) (after i2c_write_address())
	i2c_write_byte((bVal>>8)&0xff); // send upper byte
	i2c_write_byte((bVal)&0xff);    // send lower byte
	i2c_stop(); // stop current i2c transaction
	return ack;
}

/* ------------------------------------------------------------ */
/*        HYGROI2C::readRegI2C
**
**        Synopsis:
**				readRegI2C(bReg, rVal, delay_ms);
**
**        Parameters:
**				uint8_t bReg - the register address to be written to
**				uint16_t* rVal - the return location for the read bytes
**				unsigned int delay_ms - the number of milliseconds required for the HYGRO to convert the desired data
**
**        Return Values:
**                bool success - whether valid data has been successfully captured
**
**        Errors:
**			failure on bad rVal pointer
**
**        Description:
**			This function reads a register over I2C. 
**
*/
 uint8_t hygroi2c_readRegI2C(uint8_t bReg, uint16_t *rVal, uint32_t delay_in_ms)
 {
	int n, i;
	uint8_t ack;
    char msg[20]; 
	i2c_write_address(HYGROI2C_I2C_ADDR<<1); // start i2c by writing slave address (returns slave ack)
    i2c_write_byte(bReg); // write to slave (returns slave ack) (after i2c_write_address())
	if (delay_in_ms > 0)
		delay_ms(delay_in_ms); // wait for conversion to complete
	i2c_stop(); // stop current i2c transaction	
	

	ack = i2c_write_address(((HYGROI2C_I2C_ADDR<<1) | 0x01)); // start i2c by writing slave address (returns slave ack)
    //read two bytes from slave
	*rVal |= (uint16_t)i2c_read_byte(); //read a byte from the slave (after i2c_write_address())
	*rVal <<= 8;
	*rVal |= (uint16_t)i2c_read_byte(); //read a byte from the slave (after i2c_write_address()) 
    i2c_stop(); // stop current i2c transaction

    return ack;
}


/* ------------------------------------------------------------ */
/*        HYGROI2C::begin
**
**        Synopsis:
**				myHYGROI2C.begin();
**
**        Parameters:
**
**        Return Values:
**                void 
**
**        Errors:
**
**        Description:
**				This function initializes the I2C interface #1 that is used to communicate with PmodAD2.
**
*/
void hygroi2c_begin()
{
    uint8_t ack;
	delay_ms(15);
	ack = hygroi2c_writeRegI2C(HYGROI2C_CONFIG_REG, 0x00); // use non-sequential acquisition mode, all other config bits are default
	if(!ack){
        //uart_print("hygroi2c_begin() FAILED\n");
    }

	
}

/* ------------------------------------------------------------ */
/*        HYGROI2C::getTemperature
**
**        Synopsis:
**				myHYGROI2C.getTemperature();
**
**        Parameters:
**
**        Return Values:
**                float deg_c - the temperature reading in degrees celsius
**
**        Errors: - modify to manage read failures
**
**        Description:
**				This function captures a temperature reading from the Pmod HYGRO.
**
*/
float hygroi2c_getTemperature()
{
    uint8_t ack;
	uint16_t raw_t;
	float deg_c;
	ack = hygroi2c_readRegI2C(HYGROI2C_TMP_REG, &raw_t, 7); // conversion time for temperature at 14 bit resolution is 6.5 ms
	deg_c = (float)raw_t / 0x10000;
	deg_c *= 165.0;
	deg_c -= 40.0; // conversion provided in reference manual
	return deg_c;
}

/* ------------------------------------------------------------ */
/*        HYGROI2C::getHumidity
**
**        Synopsis:
**				HYGROI2C.getHumidity();
**
**        Parameters:
**
**        Return Values:
**                float per_rh - the humidity reading in percent relative humidity.
**
**        Errors: - modify to manage read failures
**
**        Description:
**				This function captures a humidity reading from the Pmod HYGRO.
**
*/
float hygroi2c_getHumidity() {
	uint16_t raw_h;
	float per_rh;
	uint8_t ack;
	ack = hygroi2c_readRegI2C(HYGROI2C_HUM_REG, &raw_h, 7); // conversion time for humidity at 14 bit resolution is 6.35 ms
	per_rh = (float)raw_h / 0x10000;
	per_rh *= 100.0; // conversion provided in reference manual
	return per_rh;
}

/* ------------------------------------------------------------ */
/*        HYGROI2C::tempF2C
**
**        Synopsis:
**				HYGROI2C.tempF2C(deg_f);
**
**        Parameters:
**				float deg_f - the temperature in degrees fahrenheit
**        Return Values:
**              float deg_c - the temperature in degrees celsius
**
**        Errors:
**
**        Description:
**				This function converts a fahrenheit temperature to celsius
**
*/
float hygroi2c_tempF2C(float deg_f)
{
	return (deg_f - 32) / 1.8;
}

/* ------------------------------------------------------------ */
/*        HYGROI2C::tempC2F
**
**        Synopsis:
**				HYGROI2C.tempC2F(deg_c);
**
**        Parameters:
**              float deg_c - the temperature in degrees celsius
**        Return Values:
**				float deg_f - the temperature in degrees fahrenheit
**
**        Errors:
**
**        Description:
**				This function converts a celsius temperature to fahrenheit
**
*/
float hygroi2c_tempC2F(float deg_c)
{
	return deg_c * 1.8 + 32;
}



