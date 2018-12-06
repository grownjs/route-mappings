/* eslint-disable no-unused-expressions */

const { expect } = require('chai');
const RouteMapper = require('../lib');

/* global beforeEach, describe, it */

let routeMapper;
let urlFor;

describe('RouteMapper()', () => {
  beforeEach(() => {
    routeMapper = RouteMapper({ use: ['app'] })
      .get('/', { to: 'Home#index', as: 'root' })
      .get('/login', { to: 'Session#new', x: 'y', as: 'showLogin' })
      .post('/login', { to: 'Session#create', p: 'q', as: 'doLogin' })
      .delete('/logout', { to: 'Session#destroy', use: ['quit'], as: 'doLogout' })
      .get('/resetPassword', { to: 'Sessions#resetShow', as: 'showReset' })
      .put('/resetPassword', { to: 'Sessions#resetUpdate', as: 'doReset' })
      .post('/resetPassword', { to: 'Sessions#resetCreate', as: 'newReset' })
      .resources(['/Users', '/Branches'], { use: ['abc', 'xyz'] })
      .resources('/Documents', () => RouteMapper()
        .get('/other', 'Documents#other')
        .get('/Section', { to: 'Documents#section', use: ['sub'] })
        .resources('/Editions', { a: 'b', use: ['other'], as: 'Editions' }))
      .namespace('/InstallationManager', () => RouteMapper({ use: ['extra'] })
        .get('/', 'Home#index')
        .get('/login', { to: 'Sessions#new' })
        .post('/login', { to: 'Sessions#create' })
        .delete('/logout', { to: 'Sessions#destroy' })
        .get('/resetPassword', { to: 'Sessions#resetShow', as: 'reset' })
        .put('/resetPassword', { to: 'Sessions#resetUpdate', as: 'reset' })
        .post('/resetPassword', { to: 'Sessions#resetCreate', as: 'reset' })
        .resources('/Users', { use: ['auth'] })
        .resources('/Installations', { as: 'Installations' }, () => RouteMapper({ use: ['track'] })
          .put('/:a/:b', { as: 'ab' })
          .resources('/Dependencies', { as: 'Dependencies' })));

    urlFor = routeMapper.mappings;
  });

  it('should mount / as `root`', () => {
    expect(urlFor.root.handler).to.eql(['Home', 'index']);
    expect(urlFor.root.path).to.eql('/');
    expect(urlFor.root.verb).to.eql('GET');
    expect(urlFor.root.use).to.eql(['app']);
  });

  it('should mount /login as `doLogin`', () => {
    expect(urlFor.doLogin.handler).to.eql(['Session', 'create']);
    expect(urlFor.doLogin.path).to.eql('/login');
    expect(urlFor.doLogin.verb).to.eql('POST');
    expect(urlFor.doLogin.use).to.eql(['app']);
    expect(urlFor.doLogin.p).to.eql('q');
    expect(urlFor.showLogin.handler).to.eql(['Session', 'new']);
    expect(urlFor.showLogin.path).to.eql('/login');
    expect(urlFor.showLogin.verb).to.eql('GET');
    expect(urlFor.showLogin.use).to.eql(['app']);
    expect(urlFor.showLogin.x).to.eql('y');
  });

  it('should mount /logout as `doLogout`', () => {
    expect(urlFor.doLogout.handler).to.eql(['Session', 'destroy']);
    expect(urlFor.doLogout.path).to.eql('/logout');
    expect(urlFor.doLogout.verb).to.eql('DELETE');
    expect(urlFor.doLogout.use).to.eql(['app', 'quit']);
    expect(urlFor.doLogout.x).to.be.undefined;
    expect(urlFor.doLogout.p).to.be.undefined;
  });

  it('should mount /resetPassword as `doReset`', () => {
    expect(urlFor.doReset.handler).to.eql(['Sessions', 'resetUpdate']);
    expect(urlFor.doReset.path).to.eql('/reset-password');
    expect(urlFor.doReset.use).to.eql(['app']);
  });

  it('should mount /InstallationManager/resetPassword as `InstallationManager.reset`', () => {
    expect(urlFor.InstallationManager.reset.handler).to.eql(['InstallationManager', 'Sessions', 'resetCreate']);
    expect(urlFor.InstallationManager.reset.path).to.eql('/installation-manager/reset-password');
    expect(urlFor.InstallationManager.reset.use).to.eql(['extra']);
  });

  it('should mount routes and resources properly', () => {
    expect(urlFor.Documents.path).to.eql('/documents');
    expect(urlFor.Documents.Section.path).to.eql('/documents/:document_id/section');
    expect(urlFor.Documents.Editions.path).to.eql('/documents/:document_id/editions');
    expect(urlFor.InstallationManager.Installations.ab.path).to.eql('/installation-manager/installations/:installation_id/:a/:b');
  });

  it('should pass data through all mounted routes properly', () => {
    expect(urlFor.Users.use).to.eql(['app', 'abc', 'xyz']);
    expect(urlFor.Branches.use).to.eql(['app', 'abc', 'xyz']);
    expect(urlFor.Documents.use).to.eql(['app']);
    expect(urlFor.Documents.Section.use).to.eql(['sub']);
    expect(urlFor.Documents.Editions.use).to.eql(['other']);
    expect(urlFor.InstallationManager.Users.use).to.eql(['extra', 'auth']);
    expect(urlFor.InstallationManager.Installations.Dependencies.use).to.eql(['track']);
  });

  it('should mount /Users and /Branches on its own namespaces', () => {
    expect(urlFor.Users.path).to.eql('/users');
    expect(urlFor.Branches.new.path).to.eql('/branches/new');
    expect(urlFor.Branches.show.path).to.eql('/branches/:id');
    expect(urlFor.Branches.edit.path).to.eql('/branches/:id/edit');
  });

  it('should mount /Installations within /InstallationManager (namespace > resources)', () => {
    expect(urlFor.InstallationManager.Installations.destroy.path).to.eql('/installation-manager/installations/:id');
    expect(urlFor.InstallationManager.Installations.edit.url(123)).to.eql('/installation-manager/installations/123/edit');
    expect(urlFor.InstallationManager.Installations.edit.handler).to.eql(['InstallationManager', 'Installations', 'edit']);
  });

  it('should mount /Dependencies within /Installations (resources > resources)', () => {
    expect(urlFor.InstallationManager.Installations.Dependencies.edit.path)
      .to.eql('/installation-manager/installations/:installation_id/dependencies/:id/edit');
    expect(urlFor.InstallationManager.Installations.Dependencies.edit.url(1, 2))
      .to.eql('/installation-manager/installations/1/dependencies/2/edit');
  });

  it('should provide [Editions] as handler, without nesting (resources > resources)', () => {
    expect(urlFor.Documents.Editions.edit.path).to.eql('/documents/:document_id/editions/:id/edit');
    expect(urlFor.Documents.Editions.edit.handler).to.eql(['Documents', 'Editions', 'edit']);
  });

  it('should return all properties from the given object as configuration (simple method)', () => {
    expect(urlFor.doLogin.p).to.eql('q');
  });

  it('should return all properties from the given object as configuration (resource method)', () => {
    expect(urlFor.Documents.Editions.a).to.eql('b');
  });
});
