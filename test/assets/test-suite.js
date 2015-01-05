
mocha.setup('bdd');
var assert = chai.assert;
describe('syntax-testers.js', function(){
  it('should run assignment expressions correctly', function(){
    var result = Test.AssignmentExpression(6);
    assert.equal(result, 8);
  });
  it('should run array expressions correctly', function(){
    var result = Test.ArrayExpression(3,4);
    assert.equal(result, 7);
  });
  it('should run block statements correctly', function(){
    var result = Test.BlockStatement(2);
    assert.equal(result, 7);
  });
  it('should run binary expressions correctly', function(){
    var result = Test.BinaryExpression(6,7);
    assert.equal(result, 26);
  });
  it('should run if/else expressions correctly', function(){
    var result1 = Test.IfStatement(2),
        result2 = Test.IfStatement(7);
    assert.equal(result1, 4);
    assert.equal(result2, 5);
  });
  after(function(){
    if(window.__Lichtenberg){
      __Lichtenberg.done();
    }
  });
});
if(window.mochaPhantomJS){
  mochaPhantomJS.run();
}else{
  mocha.run();
}
