-- --------------------------------------------------------
-- Värd:                         192.168.2.110
-- Server version:               5.5.44-MariaDB - Source distribution
-- Server OS:                    Linux
-- HeidiSQL Version:             9.1.0.4867
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;

-- Dumping database structure for TempDB
CREATE DATABASE IF NOT EXISTS `TempDB` /*!40100 DEFAULT CHARACTER SET utf8 */;
USE `TempDB`;


-- Dumping structure for table TempDB.RoomIndex
CREATE TABLE IF NOT EXISTS `RoomIndex` (
  `RoomID` int(11) NOT NULL,
  `RoomName` char(255) DEFAULT NULL,
  `RoomDescription` varchar(3000) DEFAULT NULL,
  PRIMARY KEY (`RoomID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Data exporting was unselected.


-- Dumping structure for table TempDB.SensorData
CREATE TABLE IF NOT EXISTS `SensorData` (
  `Number` int(11) NOT NULL AUTO_INCREMENT,
  `Timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Sensor` int(11) NOT NULL,
  `Temp` float NOT NULL,
  `RoomID` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`Number`),
  KEY `Sensor` (`Sensor`),
  CONSTRAINT `FK_SensorData_SensorIndex` FOREIGN KEY (`Sensor`) REFERENCES `SensorIndex` (`SensorID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Data exporting was unselected.


-- Dumping structure for table TempDB.SensorIndex
CREATE TABLE IF NOT EXISTS `SensorIndex` (
  `SensorID` int(11) NOT NULL AUTO_INCREMENT,
  `SensorName` char(100) DEFAULT NULL,
  `SensorDescription` varchar(2000) DEFAULT NULL,
  PRIMARY KEY (`SensorID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Data exporting was unselected.
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
