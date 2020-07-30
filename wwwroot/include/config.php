<?php
/**
 * this File is part of OpenVPN-WebAdmin - (c) 2020 OpenVPN-WebAdmin
 *
 * NOTICE OF LICENSE
 *
 * GNU AFFERO GENERAL PUBLIC LICENSE V3
 * that is bundled with this package in the file LICENSE.md.
 * It is also available through the world-wide-web at this URL:
 * https://www.gnu.org/licenses/agpl-3.0.en.html
 *
 * @fork Original Idea and parts in this script from: https://github.com/Chocobozzz/OpenVPN-Admin
 *
 * @author    Wutze
 * @copyright 2020 OpenVPN-WebAdmin
 * @link			https://github.com/Wutze/OpenVPN-WebAdmin
 * @see				Internal Documentation ~/doc/
 * @version		1.1.1
 * @todo			new issues report here please https://github.com/Wutze/OpenVPN-WebAdmin/issues
 */

(stripos($_SERVER['PHP_SELF'], basename(__FILE__)) === false) or die('access denied?');

	$dbhost = 'db.home';
	$dbport = '3306';
	$dbname = 'tester';
	$dbuser = 'tester';
	$dbpass = 'tester';
	$dbtype = 'mysqli';
	$dbdebug = false;
	$sessdebug = false;

	/* Site-Name */
	define('_SITE_NAME',"OVPN-WebAdmin");
	define('HOME_URL',"vpn.home");
	define('_DEFAULT_LANGUAGE','de_DE');

	/** Login Site */
	define('_LOGINSITE','login1');

	/**
	 * enable modssl
	 */
	define('modssl',TRUE);
	if (defined('modssl')){
		include(REAL_BASE_DIR.'/include/html/modules/ssl/class/class.modssl.php');
	}

	/** 
	 * only for development!
	 * please comment out if no longer needed!
	 */
	define('dev','dev/dev.php');
	if (defined('dev')){
		include_once('dev/class.dev.php');
	}
?>