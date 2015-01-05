Test = {
  AssignmentExpression: function(n){
    var x = n;
    var y = x+2;
    return y;
  },
  ArrayExpression: function(a, b){
    var list = [a, b];
    return list.reduce(function(a,b){
      return a+b;
    });
  },
  BlockStatement: function(n){
    var x, y = 5;
    {
      x = n;
      y += x;
    }
    return y;
  },
  BinaryExpression: function(a, b){
    var x, y, z;
    z = (x = a) + (y = b);
    return x + y + z;
  },
  NamedFunctionCall: function(n){
    function foo(){
      return n+1;
    }
    return foo();
  },
  AnonymousFunctionCall: function(n){
    return (function(){
      return n+1;
    })();
  },
  TryCatch: function(n){
    try{
      if(n<0){
        throw new Error("n < 0");
      }
      n += 1;
    }catch(e){
      n *= -1;
    }finally{
      return n+2;
    }
  },
  IfStatement: function(n){
    if(n < 5) {
      return n+2;
    } else {
      return n-2;
    }
  }
};
