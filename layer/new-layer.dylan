module: new-layer

define open abstract class <layer> (<object>)
  slot layer-name :: <symbol>, init-keyword: name:;
  constant slot properties :: <table> = make(<table>);
  constant each-subclass slot default-name :: <symbol>;
  slot upper-layers :: <sequence> = #();
  slot lower-layers :: <sequence> = #();
  slot sockets :: <list> = #();
end;

define method print-object (layer :: <layer>, stream :: <stream>) => ()
  format(stream, "%s", layer.layer-name);
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
  
  lower.upper-layers := add(lower.upper-layers, upper);
  upper.lower-layers := add(upper.lower-layers, lower);
  block ()
    register-upper-layer(lower, upper);
    block ()
      register-lower-layer(upper, lower);
    exception (e :: <error>)
      deregister-upper-layer(lower, upper);
      signal(e);
    end;
  exception (e :: <error>)
    lower.upper-layers := remove(lower.upper-layers, upper);
    upper.lower-layers := remove(upper.lower-layers, lower);
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
  deregister-all-property-changed-events(lower, upper);
  deregister-all-property-changed-events(upper, lower);  
  lower.upper-layers := remove(lower.upper-layers, upper);
  upper.lower-layers := remove(upper.lower-layers, lower);
end;

define function delete-layer (layer :: <layer>)
  layer.@administrative-state := #"invalid";
  for (upper in layer.upper-layers)
    disconnect-layer(layer, upper);
  end;
  for (lower in layer.lower-layers)
    disconnect-layer(lower, layer);
  end;
  remove-key!($layer-registry, layer.layer-name);
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

define function print-layer (out :: <stream>, layer :: <layer>) => ()
  format(out, "%s %s\n", layer.default-name, layer.layer-name);
  do(curry(print-property, out), get-properties(layer));
  format(out, "  services ");
  do(curry(format, out, "%s "), map(layer-name, layer.upper-layers));
  format(out, "\n  sources ");
  do(curry(format, out, "%s "), map(layer-name, layer.lower-layers));
  format(out, "\n\n");
end;

define function print-config (stream :: <stream>, layer :: <layer>) => ()
  format(stream, "%s %s\n", layer.default-name, layer.layer-name);
  for (prop in properties(layer))
    if (instance?(prop, <user-property>))
      if (property-set?(prop.property-value))
        unless (prop.property-default-value = prop.property-value)
          print-property(stream, prop);
        end;
      end;
    end;
  end;
  if (layer.upper-layers.size > 0)
    format(stream, "  services ");
    do(curry(format, stream, "%s "), map(layer-name, layer.upper-layers));
    format(stream, "\n");
  end;
  format(stream, "\n");
end;

define constant $unset = pair($unset, $unset);

define inline function property-set?(object) => (unset? :: <boolean>)
  object ~== $unset
end;

define inline function unset-or (type)
  type-union(singleton($unset), type);
end;

define macro layer-getter-and-setter-definer
    { layer-getter-and-setter-definer(?:name) }
      => {  }
    { layer-getter-and-setter-definer(?:name; ?attrs:* slot ?rest2:*; ?rest:*) }
      => { layer-getter-and-setter-definer(?name; ?rest) }
    { layer-getter-and-setter-definer(?:name; inherited property ?rest2:*; ?rest:*) }
      => { layer-getter-and-setter-definer(?name; ?rest) }
    { layer-getter-and-setter-definer(?:name; ?attr:* property ?pname:name :: ?type:expression = ?default:*; ?rest:*) }
      => { 
       define method "@" ## ?pname (lay :: ?name) => (res :: ?type)
         get-property-value(lay, ?#"pname");
       end;
       define method "@" ## ?pname ## "-setter" (new-val :: unset-or(?type), lay :: ?name) => (res :: ?type)
	 if (new-val == $unset)
	   set-property-value(lay, ?#"pname", ?default)
	 else
	   set-property-value(lay, ?#"pname", new-val)
	 end;
       end;
       layer-getter-and-setter-definer(?name; ?rest) }
    { layer-getter-and-setter-definer(?:name; ?attr:* property ?pname:name :: ?type:expression ?foo:*; ?rest:*) }
      => { 
       define method "@" ## ?pname (lay :: ?name) => (res :: unset-or(?type))
         get-property-value(lay, ?#"pname");
       end;
       define method "@" ## ?pname ## "-setter" (new-val :: unset-or(?type), lay :: ?name) => (res :: ?type)
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
    { ?attrs:* slot ?rest:*; ... } => { ... }
    { inherited property ?:name = ?default:expression; ... } =>
       { owner.properties[?#"name"].property-default-value := ?default;
	 owner.properties[?#"name"].property-value := ?default;
	 ... }
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
  { layer-class-definer(?attr:*; ?:name (?superclasses:*); ?properties:*) }
 => { define ?attr class "<" ## ?name ## "-layer>" (?superclasses)
        inherited slot default-name = ?#"name";
        ?properties
      end }

  properties:
    { } => { }
    { ?attrs:* slot ?rest:*; ... } => { ?attrs slot ?rest; ... }
    { ?attr:* property ?foo:*; ... } => { ... }
end;

define open generic initialize-layer (layer :: <layer>, #key, #all-keys) => ();
  
define method initialize-layer (layer :: <layer>, #key, #all-keys) => () end;

define macro layer-definer
 { define ?attr:* layer ?:name (?superclasses:*)
     ?properties:*
   end }
 =>
 { layer-getter-and-setter-definer("<" ## ?name ## "-layer>"; ?properties);
   layer-class-definer(?attr; ?name (?superclasses); ?properties);

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

layer-getter-and-setter-definer(<layer>; property administrative-state :: <symbol> = #"down";);
layer-getter-and-setter-definer(<layer>; system property running-state :: <symbol> = #"down";);

define method initialize (layer :: <layer>,
                          #next next-method, #rest rest, #key name, #all-keys);
  next-method();
  add-properties-to-table(layer; property administrative-state :: <symbol> = #"down";);
  add-properties-to-table(layer; system property running-state :: <symbol> = #"down";);
end;

define inline function init-properties (layer :: <layer>, args :: <collection>)
  for (i from 0 below args.size by 2)
    unless (args[i] == #"name")
      if (element(layer.properties, args[i], default: #f))
        let prop = get-property(layer, args[i]);
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
  do(method (x) x(event) end, map(head, source.listeners))
end;

define inline function register-property-changed-event
    (source :: <layer>, name :: <symbol>, callback :: <function>, #key owner) => ()
  let prop = get-property(source, name);
  prop.listeners := add!(prop.listeners, pair(callback, owner));
  if (property-set?(prop.property-value))
    let event = make(<property-changed-event>,
                     property: prop,
                     old-value: prop.property-value);
    callback(event);
  end;
end;

define inline function deregister-property-changed-event
    (source :: <layer>, name :: <symbol>, callback :: <function>) => ()
  let prop = get-property(source, name);
  prop.listeners := choose(method(x) x.head ~== callback end, prop.listeners);
end;

define inline function deregister-all-property-changed-events
    (source :: <layer>, owner) => ()
  for (prop in source.get-properties)
    prop.listeners := choose(method(x) x.tail ~== owner end, prop.listeners);
  end;
end;

define abstract class <property> (<event-source>)
  constant slot property-name :: <symbol>, init-keyword: name:;
  constant slot property-type :: <type>, init-keyword: type:;
  slot property-default-value = $unset, init-keyword: default:;
  slot %property-value = $unset, init-keyword: value:;
  constant slot property-owner :: <layer>, init-keyword: owner:;
end;

define class <system-property> (<property>) end;
define class <user-property> (<property>) end;

define open generic check-property (owner, property-name :: <symbol>, value)
 => ();

define method check-property (owner, property-name :: <symbol>, value) => ()
  //move along
end;

define generic print-property-value (stream :: <stream>, value);

define method print-property-value (stream :: <stream>, value :: <object>);
  print-object(value, stream);
end;

define method print-property-value (stream :: <stream>, value :: <symbol>);
  format(stream, "%s", value);
end;

define method print-property-value (stream :: <stream>, value :: <string>);
  format(stream, "%s", value);
end;

define method print-property-value (stream :: <stream>, value :: <boolean>);
  if (value)
    write(stream, "true")
  else
    write(stream, "false")
  end
end;

define method print-property-value (stream :: <stream>, value == $unset);
  write(stream, "not set")
end;

define inline function print-property (stream :: <stream>, prop :: <property>) => ()
  format(stream, "  %s ", prop.property-name);
  print-property-value(stream, prop.property-value);
  write(stream, "\n");
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

define method read-as (type == <layer>, value :: <string>) => (res :: <layer>)
  find-layer(value);
end;

define method read-as (type == <boolean>, value :: <string>) => (res :: <boolean>)
  if ((value = "#t") | (value = "true") | (value = "t"))
    #t;
  end;
end;

define method read-as (type == <integer>, value :: <string>) => (res :: <integer>)
  string-to-integer(value);
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

define function empty-line? (line :: <string>)
  regex-search("^\\s*$", line) & #t
end;

define function read-config (stream :: <stream>)
  flush-config();
  let property-changes = make(<table>);
  while(~ stream-at-end?(stream))
    block(skip)
      let line = read-line(stream);
      if (empty-line?(line))
        skip();
      end;
      let (class, name) = apply(values, split(line, ' '));
      let layer-type = class & find-layer-type(class);
      unless (layer-type)
        error("Parse error reading config: unknown layer type %=", class);
      end;
      unless (name)
        error("Parse error reading config: invalid layer name %=", name);
      end;
      name := as(<symbol>, name);
      let layer = find-layer(name) | make(layer-type, name: name);
      property-changes[layer] := #();
      block (next)
        while (~ stream-at-end?(stream))
          let line = read-line(stream);
          if (empty-line?(line))
            next();
          end;
          let (_full, property-name, value) = regex-search-strings("^\\s+(\\S*)\\s+(.*)$",
                                                                   line);
          unless (property-name)
            error("Parse error reading config for %s %s: invalid property name", class, name);
          end;
          property-name := as(<symbol>, property-name);
          unless (element(layer.properties, property-name, default: #f) 
                    | property-name == #"services")
            error("Parse error reading config for %s %s: unknown property %s", class, name, property-name);
          end;
          if (value)
            property-changes[layer] := pair(pair(property-name, value), property-changes[layer]);
          end;
        end;
      end;
    end;
  end;
  for (layer in key-sequence(property-changes))
    for (prop in property-changes[layer])
      unless (prop.head == #"services")
        read-into-property(get-property(layer, prop.head), prop.tail);
      end
    end
  end;
  for (layer in key-sequence(property-changes))
    for (prop in property-changes[layer])
      if (prop.head == #"services")
        let uppers = split(prop.tail, " ");
        for (upper in uppers)
          unless (empty-line?(upper))
            connect-layer(layer, find-layer(upper));
          end
        end
      end
    end
  end;
end;

define function flush-config ()
  let layers = shallow-copy($layer-registry);
  for (layer in layers)
    delete-layer(layer);
  end;
end;
 