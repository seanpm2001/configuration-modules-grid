# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}
#

declaration template components/dpmlfc/schema;

include { 'quattor/schema' };

function component_dpmlfc_global_options_valid = {
  if ( !is_defined(SELF) ) {
    error('Internal error: DPM/LFC global options undefined in validation function');
    return(false);
  };
  
  if ( exists(SELF['accessProtocols']) && is_defined(SELF['accessProtocols']) ) {
    if ( !is_list(SELF['accessProtocols']) ) {
      error("Global option 'accessProtocols' must be a list");
      return(false);
    };
    foreach (i;protocol;SELF['accessProtocols']) {
      if ( !match(protocol,'https|gsiftp|rfio|xroot') ) {
        error('Invalid DPM access protocol specified ('+protocol+'). Must be https, gsiftp, rfio or xroot');
        return(false);
      };
    };
  };
  
  if ( exists(SELF['controlProtocols']) && is_defined(SELF['controlProtocols']) ) {
    if ( !is_list(SELF['controlProtocols']) ) {
      error("Global option 'controlProtocols' must be a list");
      return(false);
    };
    foreach (i;protocol;SELF['controlProtocols']) {
      if ( !match(protocol,'srmv1|srmv2|srmv2.2') ) {
        error('Invalid DPM control protocol specified ('+protocol+'). Must be srmv1, srmv2 or srmv2.2');
        return(false);
      };
    };
  };
  
  true;  
};

# Validation of xroot access rules
function component_dpmlfc_xroot_access_rules_valid = {
  if ( !is_defined(SELF) ) {
    error('Internal error: DPM xroot access rules undefined in validation function');
    return(false);
  };
  
  foreach (i;operation_type;list('authenticated','unauthenticated')) {
    if ( is_defined(SELF[operation_type]) ) {
      foreach (j;operation;SELF[operation_type]) {
        if ( !match(operation,'^(delete|read|write|write-once)$') ) {
          error('Invalid operation ('+operation+') specified in xroot access rules for '+operation_type+' operations');
          return(false);
        }; 
      };
    };
  };
  true;
};

# Validation of node parameters
function component_dpmlfc_node_config_valid = {
  # Check 'requestMaxAge is a valid value. See man dpm.
  if ( is_defined(SELF['requestMaxAge']) ) {
    if ( !match(SELF['requestMaxAge'],'^[0-9]+[ymdh]*$') ) {
      error("'requestMaxAge' must be a number optionally followed by 'y' (year), 'm' (month), 'd' (day) or 'h' (hour).");
      return(false);
    }
  };
  true;
};


type ${project.artifactId}_component_fs_entry = {
        "host"     ? string
        "name"     ? string
        "status"     ? string
};

type ${project.artifactId}_component_pool_entry = {
        "def_filesize"    ? string
        "gc_start_thresh" ? long(0..)
        "gc_stop_thresh"  ? long(0..)
        "def_pintime"     ? long(0..)
        "gid"             ? long(1..)
        "group"           ? string
        "put_retenp"      ? long(0..)
        "s_type"          ? string with match (SELF,'-|D|P|V')
        "fs"              ? ${project.artifactId}_component_fs_entry[]
};

type ${project.artifactId}_component_vo_entry = {
        "gid"     ? long = -1
};

type ${project.artifactId}_component_node_config = {
        "host"      ? string
        "logfile"   ? string
        "port"      ? type_port
        "assumekernel" ? string
        "allowCoreDump" ? boolean
} with component_dpmlfc_node_config_valid(SELF);

type ${project.artifactId}_component_dpm_node_config = {
        include ${project.artifactId}_component_node_config
        "requestMaxAge" ? string
};

# xrootd authentication plug-in allow to specify operations requiring
# authentication and those allowed without authentication (authentication will be
# used if present).
type ${project.artifactId}_component_xroot_access_rules = {
  'path' : string
  'authenticated' : string[]
  'unauthenticated' : string[]
  'vo' : string = '*'
  'cert' : string = '*'
} with component_dpmlfc_xroot_access_rules_valid(SELF);

# xrootd has several specific options
type ${project.artifactId}_component_xroot_options = {
        "installDir" ? string
        "ofsPlugin" : string = 'Ofs'
        "cmsDaemon" : string = 'cmsd' with match(SELF,'cmsd|olbd')
        "configDir" : string = 'xrootd'
        "config"    : string = 'xrd.dpm.cf'
        "exportedVOs" ? string[]
        "MonALISAHost" ? string
        "authzConf" : string = 'xrd.authz.cf'
        "tokenPrivateKey" ? string
        "tokenPublicKey" ? string
        "accessRules" ? ${project.artifactId}_component_xroot_access_rules[]
};

type ${project.artifactId}_component_db_conn_options = {
        "type"          ? string
        "configfile"    ? string
        "configmode"    ? string = '600'
        "server"        ? string
        "user"          : string = "dpmmgr"
        "password"      : string
#        "oldpassword"   ? string  # to be used when changing password
        "adminuser"     : string
        "adminpwd"      : string
#        "oldadminpwd"   ? string  # to be used when changing password
        "infoFile"      ? string
        "infoUser"      ? string
        "infoPwd"       ? string
};

type ${project.artifactId}_component_global_options = {
        "user"        ? string
        "group"       ? string
        "db"          ? ${project.artifactId}_component_db_conn_options
        "xroot"       ? ${project.artifactId}_component_xroot_options
        "installDir"  ? string = '/opt/lcg'
        "gridmapfile" ? string
        "gridmapdir"  ? string
        "accessProtocols"   ? string[]
        "controlProtocols"   ? string[]
} with component_dpmlfc_global_options_valid(SELF);

type ${project.artifactId}_component_global_options_tree = {
        "dpm"     ? ${project.artifactId}_component_global_options
        "lfc"     ? ${project.artifactId}_component_global_options
};

type ${project.artifactId}_component = {
	include structure_component

        "dpm"      ? ${project.artifactId}_component_dpm_node_config[]
        "dpns"     ? ${project.artifactId}_component_node_config[]
        "gsiftp"   ? ${project.artifactId}_component_node_config[]
        "rfio"     ? ${project.artifactId}_component_node_config[]
        "srmv1"    ? ${project.artifactId}_component_node_config[]
        "srmv2"    ? ${project.artifactId}_component_node_config[]
        "srmv22"   ? ${project.artifactId}_component_node_config[]
        "xroot"    ? ${project.artifactId}_component_node_config[]
        "copyd"    ? ${project.artifactId}_component_node_config[]

        "pools"    ? ${project.artifactId}_component_pool_entry{}
        "vos"      ? ${project.artifactId}_component_vo_entry{}

        "lfc"      ? ${project.artifactId}_component_node_config[]
        "lfc-dli"  ? ${project.artifactId}_component_node_config[]

	      "options"  ? ${project.artifactId}_component_global_options_tree
};

bind "/software/components/dpmlfc" = ${project.artifactId}_component;


