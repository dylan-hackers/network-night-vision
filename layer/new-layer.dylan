module: new-layer

define open abstract class <layer> (<object>)
  slot layer-name :: <symbol>, init-keyword: name:;
  slot properties :: <table> = make(<table>);
  constant each-subclass slot default-name :: <symbol>;
  slot upper-layers :: <sequence> = #();
  slot lower-layers :: <sequence> = #();
end;

define open generic register-lower-layer (upper :: <layer>, lower :: <layer>);
define open generic register-upper-layer (lower :: <layer>, upper :: <layer>);

define method register-lower-layer (upper :: <layer>, lower :: <layer>)
end;

define method register-upper-layer (lower :: <layer>, upper :: <layer>);
end;

define open generic deregister-lower-layer (upper :: <layer>, lower :: <layer>);
define open generic deregister-upper-layer (lower :: <layer>, upper :: <layer>);

define method deregister-lower-layer (upper :: <layer>, lower :: <layer>)
end;

define method deregister-upper-layer (lower :: <layer>, upper :: <layer>);
end;

define open generic check-lower-layer? (upper :: <layer>, lower :: <layer>) => (allowed? :: <boolean>);
define open generic check-upper-layer? (lower :: <layer>, upper :: <layer>) => (allowed? :: <boolean>);

define method check-lower-layer? (upper :: <layer>, lower :: <layer>) => (allowed? :: <boolean>)
  #f
end;

define method check-upper-layer? (lower :: <layer>, upper :: <layer>) => (allowed? :: <boolean>);
  #f
end;

define function connect-layer (lower :: <layer>, upper :: <layer>) => ();
  if (member?(upper, lower.upper-layers)
       | member?(lower, upper.lower-layers))
    error("Layer connection already established!")
  end;
  unless (check-upper-layer?(lower, upper))
    error("Lower layer refused new upper")
  end;
  unless (check-lower-layer?(upper, lower))
    error("Upper layer refused new lower")
  end;
  
  register-upper-layer(lower, upper);
  block ()
    register-lower-layer(upper, lower);
    lower.upper-layers := add(lower.upper-layers, upper);
    upper.lower-layers := add(upper.lower-layers, lower);
  exception (e :: <error>)
    deregister-upper-layer(lower, upper);
    signal(e);
  end;
end;

define function disconnect-layer (lower :: <layer>, upper :: <layer>) => ();
  unless (member?(upper, lower.upper-layers)
       & member?(lower, upper.lower-layers))
    error("Layers not connected")
  end;
  deregister-upper-layer(lower, upper);
  deregister-lower-layer(upper, lower);
  lower.upper-layers := remove(lower.upper-layers, upper);
  upper.lower-layers := remove(upper.lower-layers, lower);
end;

define constant <socket> = <object>;

define open generic create-raw-socket (layer :: <layer>) => (res :: <socket>);

define constant $layer-registry = make(<table>);

define constant $layer-type-registry = make(<table>);
define constant $layer-startups :: <stretchy-vector> = make(<stretchy-vector>);

define function register-startup-function (function :: <function>) => ()
  add!($layer-startups, function);
end;

define function start-layer () => ()
  do(method(x) x() end, $layer-startups);
end;

define function find-layer-type (name :: type-union(<symbol>, <string>))
 => (layer :: false-or(subclass(<layer>)))
  if (instance?(name, <string>))
    name := as(<symbol>, name);
  end;
  element($layer-type-registry, name, default: #f);
end;
define function find-layer (name :: type-union(<symbol>, <string>)) => (layer :: false-or(<layer>))
  if (instance?(name, <string>))
    name := as(<symbol>, name);
  end;
  element($layer-registry, name, default: #f);
end;

define function find-all-layers () => (layers :: <collection>)
  $layer-registry;
end;

define function print-layer (stream :: <stream>, layer :: <layer>) => ()
  format(stream, "%s %s\n", layer.default-name, layer.layer-name);
end;

define function print-config (stream :: <stream>, layer :: <layer>) => ()
  format(stream, "%s %s {\n", layer.default-name, layer.layer-name);
  for (prop in properties(layer))
    if (instance?(prop, <user-property>))
      if (slot-initialized?(prop, %property-value))
        unless (slot-initialized?(prop, property-default-value)
                & (prop.property-default-value = prop.property-value))
          format(stream, "  ");
          print-property(stream, prop);
        end;
      end;
    end;
  end;
  for (upper in layer.upper-layers)
    format(stream, "  service %s\n", upper.layer-name);
  end;
  format(stream, "}\n\n");
end;

define macro layer-getter-and-setter-definer
    { layer-getter-and-setter-definer(?:name) }
      => {  }
    { layer-getter-and-setter-definer(?:name; slot ?rest2:*; ?rest:*) }
      => { layer-getter-and-setter-definer(?name; ?rest) }
    { layer-getter-and-setter-definer(?:name; ?attr:* property ?pname:name :: ?type:expression ?foo:*; ?rest:*) }
      => { 
       define method "@" ## ?pname (lay :: ?name) => (res :: ?type)
         get-property-value(lay, ?#"pname");
       end;
       define method "@" ## ?pname ## "-setter" (new-val :: ?type, lay :: ?name) => (res :: ?type)
         set-property-value(lay, ?#"pname", new-val)
       end;
       layer-getter-and-setter-definer(?name; ?rest) }
end;

define macro add-properties-to-table
  { add-properties-to-table(?layer:name; ?properties:*) }
 => { begin
        let owner = ?layer;
        ?properties;
      end }

  properties:
    { } => { }
    { slot ?rest:*; ... } => { ... }
    { system property ?:name :: ?type:expression; ... } =>
       { owner.properties[?#"name"] := make(<system-property>,
                                           name: ?#"name",
                                           type: ?type,
                                           owner: owner);
         ...  }
    { system property ?:name :: ?type:expression = ?default:expression; ... } =>
       { owner.properties[?#"name"] := make(<system-property>,
                                           name: ?#"name",
                                           type: ?type,
                                           default: ?default,
                                           value: ?default,
                                           owner: owner);
         ...  }
    { property ?:name :: ?type:expression; ... } =>
       { owner.properties[?#"name"] := make(<user-property>,
                                           name: ?#"name",
                                           type: ?type,
                                           owner: owner);
         ...  }
    { property ?:name :: ?type:expression = ?default:expression; ... } =>
       { owner.properties[?#"name"] := make(<user-property>,
                                           name: ?#"name",
                                           type: ?type,
                                           default: ?default,
                                           owner: owner,
                                           value: ?default);
         ...  }

end;
define macro layer-class-definer
  { layer-class-definer(?attr:*; ?:name (?superclass:expression); ?properties:*) }
 => { define ?attr class "<" ## ?name ## "-layer>" (?superclass)
        inherited slot default-name = ?#"name";
        ?properties
      end }

  properties:
    { } => { }
    { slot ?rest:*; ... } => { slot ?rest; ... }
    { ?attr:* property ?foo:*; ... } => { ... }
end;

define open generic initialize-layer (layer :: <layer>, #key, #all-keys) => ();
  
define method initialize-layer (layer :: <layer>, #key, #all-keys) => () end;

define macro layer-definer
 { define ?attr:* layer ?:name (?superclass:expression)
     ?properties:*
   end }
 =>
 { layer-getter-and-setter-definer("<" ## ?name ## "-layer>"; ?properties);
   layer-class-definer(?attr; ?name (?superclass); ?properties);

   $layer-type-registry[?#"name"] := "<" ## ?name ## "-layer>";

   define variable "$" ## ?name ## "-instance-count" :: <integer> = 0;
   define method make (class == "<" ## ?name ## "-layer>",
                       #next next-method, #rest rest, #key name, #all-keys)
    => (layer :: "<" ## ?name ## "-layer>")
     unless(name)
       name := as(<symbol>, format-to-string("%s%=", ?"name", "$" ## ?name ## "-instance-count"));
       "$" ## ?name ## "-instance-count" := "$" ## ?name ## "-instance-count" + 1;
     end;
     if (element($layer-registry, name, default: #f))
       error("Can't create layer: name duplication");
     end;
     let layer = next-method();
     init-properties(layer, rest);
     layer.layer-name := name;
     $layer-registry[name] := layer;
     apply(initialize-layer, layer, rest);
     layer;
   end;

   define method initialize (layer :: "<" ## ?name ## "-layer>",
                             #next next-method, #rest rest, #key name, #all-keys);
     next-method();
     add-properties-to-table(layer; ?properties);
   end; }
end;

define inline function init-properties (layer :: <layer>, args :: <collection>)
  for (i from 0 below args.size by 2)
    unless (args[i] == #"name")
      if (get-property(layer, args[i]))
        let prop = get-property(layer, args[i]);
        prop.property-default-value := args[i + 1];
        prop.%property-value := args[i + 1];
      end;
    end;
  end;
end;
define abstract class <event> (<object>)
end;

define abstract class <event-source> (<object>)
  slot listeners = #();
end;

define inline function event-notify
    (source :: <event-source>, event :: <event>) => ()
  do(method (x) x(event) end, source.listeners)
end;

define inline function register-property-changed-event
    (source :: <layer>, name :: <symbol>, callback :: <function>) => ()
  let prop = get-property(source, name);
  prop.listeners := add!(prop.listeners, callback);
end;

define inline function deregister-property-changed-event
    (source :: <layer>, name :: <symbol>, callback :: <function>) => ()
  let prop = get-property(source, name);
  prop.listeners := remove!(prop.listeners, callback);
end;

define abstract class <property> (<event-source>)
  constant slot property-name :: <symbol>, init-keyword: name:;
  constant slot property-type :: <type>, init-keyword: type:;
  slot property-default-value, init-keyword: default:;
  slot %property-value, init-keyword: value:;
  constant slot property-owner, init-keyword: owner:;
end;

define class <system-property> (<property>) end;
define class <user-property> (<property>) end;

define open generic check-property (owner, property-name :: <symbol>, value)
 => ();

define method check-property (owner, property-name :: <symbol>, value) => ()
  //move along
end;

define inline function print-property (stream :: <stream>, prop :: <property>) => ()
  format(stream, "%s: %=\n", prop.property-name, prop.property-value);
end;
define inline function get-properties
    (object :: <layer>) => (res :: <collection>)
  object.properties
end;
define inline function get-property
    (object :: <layer>, property-name :: <symbol>)
 => (property :: <property>)
  element(object.properties, property-name);
end;

define method read-into-property
  (property :: <system-property>, value :: <string>)
  error("Unable to set system property");
end;

define method read-into-property
  (property :: <user-property>, value :: <string>)
  property.property-value := read-as(property.property-type, value);
end;

define open generic read-as (type, value) => (value);

define method read-as (type == <symbol>, value :: <string>) => (res :: <symbol>)
  as(<symbol>, value);
end;

define method read-as (type == <string>, value :: <string>) => (res :: <string>)
  value;
end;

define method read-as (type == <boolean>, value :: <string>) => (res :: <boolean>)
  if ((value = "#t") | (value = "true") | (value = "t"))
    #t;
  end;
end;

define inline function set-property-value
    (object :: <layer>, property-name :: <symbol>, new-value)
 => (value)
  get-property(object, property-name).property-value := new-value;
end;

define inline function get-property-value
    (object :: <layer>, property-name :: <symbol>)
 => (value)
  get-property(object, property-name).property-value;
end;

define inline function property-value (property :: <property>)
  %property-value(property)
end;

define inline function property-value-setter
    (value, property :: <property>) => (value)
  let old-value = property.property-value;
  check-property(property.property-owner, property.property-name, value);
  if (old-value ~= value)
    property.%property-value := value;
    let event = make(<property-changed-event>,
                     property: property,
                     old-value: old-value);
    event-notify(property, event);
  end;
  value
end;


define class <property-changed-event> (<event>)
  constant slot property-changed-event-property :: <property>,
    required-init-keyword: property:;
  constant slot property-changed-event-old-value,
    required-init-keyword: old-value:;
end;

