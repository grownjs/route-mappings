/* eslint-disable no-shadow */

const { expect } = require('chai');
const routeMappings = require('../lib');

/* global describe, it */

describe('routeMappings()', () => {
  it('is a function', () => {
    expect(typeof routeMappings).to.eql('function');
  });

  describe('DSL', () => {
    it('responds to #namespace', () => {
      expect(() => routeMappings().namespace('/Test')).not.to.throw();
    });

    it('responds to #resources', () => {
      expect(() => routeMappings().resources('/Test')).not.to.throw();
    });

    it('responds to #resource', () => {
      expect(() => routeMappings().resource('/Test')).not.to.throw();
    });

    it('responds to #get #put #post #patch #delete', () => {
      expect(() => routeMappings()
        .get('/Test')
        .put('/Test')
        .post('/Test')
        .patch('/Test')
        .delete('/Test')).not.to.throw();
    });

    it('returns as tree', () => {
      expect(() => routeMappings().tree).not.to.throw();
    });

    it('returns as routes', () => {
      expect(() => routeMappings().routes).not.to.throw();
    });

    it('returns as mappings', () => {
      expect(() => routeMappings().mappings).not.to.throw();
    });

    it('can declare mixed routes', () => {
      const $ = routeMappings()
        .get('/')
        .namespace('/', routeMappings => routeMappings()
          .get('/login')
          .post('/login')
          .delete('/logout'))
        .namespace('/Admin', routeMappings => routeMappings()
          .resource('/CMS')
          .resource('/Cats')
          .resources('/Posts', routeMappings => routeMappings()
            .resources('/Comments', { as: 'Admin.Comments' })
            .namespace('/Assets', routeMappings => routeMappings()
              .resources('/Images', { as: 'Admin.Images' }))));

      const m = $.mappings;

      expect(() => m('x.y')).to.throw();
      expect(m('login.url')).to.eql('/login');
      expect(m('login.path')).to.eql('/login');
      expect(m('login.handler')).to.eql(['login']);
      expect(() => routeMappings().get('/', () => {})).not.to.throw();
      expect(m.Admin.Posts.resource).to.eql('Post');
      expect(m.Admin.Cats.show.resource).to.eql('Cat');
      expect(m.Admin.Images.destroy.resource).to.eql('Post.Image');
      expect(m.Admin.Images.destroy.path).to.eql('/admin/posts/:post_id/assets/images/:id');
    });

    it('precompile routes as matchers', () => {
      const $ = routeMappings()
        .get('/')
        .get('/a')
        .get('/b')
        .get('/:one')
        .get('/*two')
        .get('/a/:b')
        .get('/a/:b/:c')
        .get('/a/*extra');

      const m = $.map();

      expect(m().length).to.eql(8);
    });

    it('will match on depth and priority', () => {
      const $ = routeMappings()
        .get('/*a')
        .get('/*a?')
        .get('/x/*y')
        .get('/*x/*y/*z')
        .get('/:a')
        .get('/a');

      const m = $.map();
      const b = m('/a', 1);
      const c = m('/a')[0];

      expect(b).to.eql(c);
      expect(m('/', 1).path).to.eql('/*a?');
      expect(m('/b', 1).path).to.eql('/:a');
      expect(m('/a/b', 1).path).to.eql('/*a');
      expect(m('/x/y', 1).path).to.eql('/x/*y');
      expect(m('/a/b/c', 1).path).to.eql('/*x/*y/*z');
      expect(m('/x/y/z', 1).path).to.eql('/x/*y');
    });

    it('will store parent relationships', () => {
      const $ = routeMappings()
        .get('/')
        .namespace('/admin', () => routeMappings()
          .get('/:page')
          .namespace('/db', () => routeMappings()
            .resources('/users')));

      expect($.mappings.admin.db.users.edit.keypath).to.eql(['admin.db', 'admin.db.users']);
    });

    it('can set custom placeholders', () => {
      const $ = routeMappings({ placeholder: 'foo' })
        .resources('/Example', { only: ['edit'] }).mappings;

      expect($.Example.edit.path).to.eql('/example/:foo/edit');
    });

    it('should inherit any options from parents', () => {
      const $ = routeMappings()
        .namespace('/', { lookup: '%Ctrl' }, group => group()
          .get('/health', { to: 'Test.getOK' }));

      expect($.mappings.health.lookup).to.eql('%Ctrl');
    });

    it('should allow non-path params', () => {
      const $ = routeMappings()
        .get('/foo.:bar', { to: 'Test.OSOM', as: 'foo' });

      expect($.mappings.foo.url(['42'])).to.eql('/foo.42');
    });
  });
});
