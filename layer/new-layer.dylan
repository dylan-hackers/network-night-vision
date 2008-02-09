module: new-layer

define open abstract class <layer> (<object>)
  slot layer-name :: <symbol>;
  each-subclass slot instance-count :: <integer> = 0;
  slot properties :: <table> = make(<table>);
end;

define constant $layer-registry = make(<table>);


define macro layer-getter-and-setter-definer
    { layer-getter-and-setter-definer(?:name) }
      => {  }
    { layer-getter-and-setter-definer(?:name; property ?pname:name :: ?type:expression = ?default:expression; ?rest:*) }
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
    { property ?:name :: ?type:expression = ?default:expression; ... } =>
       { owner.properties[?#"name"] := make(<property>,
                                           name: ?#"name",
                                           type: ?type,
                                           default: ?default,
                                           owner: owner,
                                           value: ?default);
                                           //getter: ?name,
                                           //setter: ?name ## "-setter");
         ...  }

end;
define macro layer-definer
 { define layer ?:name
     ?properties:*
   end }
 =>
 { layer-getter-and-setter-definer("<" ## ?name ## ">"; ?properties);
   define class "<" ## ?name ## ">" (<layer>) end;

   define method initialize (layer :: "<" ## ?name ## ">",
                             #next next-method, #rest rest, #key name, #all-keys);
     next-method();
     init-layer(layer, ?"name", name);
     add-properties-to-table(layer; ?properties);
     init-properties(layer, rest);
   end; }
end;

define function init-layer (layer :: <layer>, default-name :: <string>, name)
  unless(name)
    name := as(<symbol>, format-to-string("%s%=", default-name, layer.instance-count));
    layer.instance-count := layer.instance-count + 1;
  end;
  if (element($layer-registry, name, default: #f))
    error("Can't create layer: name duplication");
  end;
  layer.layer-name := name;
  $layer-registry[name] := layer;
end;

define function init-properties (layer :: <layer>, args :: <collection>)
  for (i from 0 below args.size by 2)
    if (get-property(layer, args[i]))
      let prop = get-property(layer, args[i]);
      prop.property-default-value := args[i + 1];
      prop.%property-value := args[i + 1];
    end;
  end;
end;
define class <event> (<object>)
end;

define class <event-source> (<object>)
  slot listeners = #();
end;

define method event-notify (source :: <event-source>, event :: <event>)
  do(method (x) x(event) end, source.listeners)
end;

define method register-event (source :: <event-source>, callback :: <function>)
  source.listeners := add!(source.listeners, callback);
end;

define method deregister-event (source :: <event-source>, callback :: <function>)
  source.listeners := remove!(source.listeners, callback);
end;

define class <property> (<event-source>)
  constant slot property-name :: <symbol>, init-keyword: name:;
  constant slot property-type :: <type>, init-keyword: type:;
  slot property-default-value, init-keyword: default:;
  slot %property-value, init-keyword: value:;
  constant slot property-owner, init-keyword: owner:;
  //constant slot property-getter, init-keyword: getter:;
  //constant slot property-setter, init-keyword: setter:;
end;

define function get-property (object :: <layer>, property-name :: <symbol>)
 => (res :: <property>)
  element(object.properties, property-name);
end;

define function set-property-value (object :: <layer>, property-name :: <symbol>, new-value)
 => (res)
  get-property(object, property-name).property-value := new-value;
end;

define function get-property-value (object :: <layer>, property-name :: <symbol>)
 => (res)
  get-property(object, property-name).property-value;
end;

define inline method property-value (property :: <property>)
  %property-value(property)
end;

define open generic check-property (owner, property-name :: <symbol>, value) => ();
define method check-property (owner, property-name :: <symbol>, value) => ()
  //move along
end;
define inline method property-value-setter (value, property :: <property>)
  let old-value = property.property-value;
  check-property(property.property-owner, property.property-name, value);
  if (old-value ~= value)
    property.%property-value := value;
    let event = make(<property-changed-event>, property: property, old-value: old-value);
    event-notify(property, event);
  end;
  value
end;


define class <property-changed-event> (<event>)
  constant slot property-changed-event-property :: <property>, required-init-keyword: property:;
  constant slot property-changed-event-old-value, required-init-keyword: old-value:;
end;

