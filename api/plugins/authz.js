'use strict';

const TENANT_HEADER = 'X-Tenant-ID';
const ADMIN_PREFIX = '/admin/';
const HTTP_METHODS = ['get', 'put', 'post', 'patch', 'delete', 'head', 'options', 'trace'];

function resolveFrom(ctx, node, base) {
  if (!node || typeof node !== 'object' || !node.$ref) return { node, base, failed: false };

  const resolved = base ? ctx.resolve(node, base) : ctx.resolve(node);
  if (!resolved || !resolved.node) return { node: undefined, base, failed: true };

  const source = resolved.location && resolved.location.source;
  return { node: resolved.node, base: (source && source.absoluteRef) || base, failed: false };
}

function takesTenantHeader(ctx, parameters, base, onUnresolved) {
  if (!Array.isArray(parameters)) return false;

  return parameters.some((entry) => {
    const { node, failed } = resolveFrom(ctx, entry, base);
    if (failed) {
      onUnresolved(entry.$ref);
      return false;
    }
    return Boolean(node) && node.in === 'header' && node.name === TENANT_HEADER;
  });
}

function eachOperation(root, ctx, visit) {
  for (const [path, pathRef] of Object.entries(root.paths || {})) {
    const { node: pathItem, base, failed } = resolveFrom(ctx, pathRef, undefined);
    if (failed || !pathItem) {
      ctx.report({ message: `Could not resolve the path item for ${path}, so it cannot be checked.` });
      continue;
    }

    const unresolved = (ref) =>
      ctx.report({ message: `Could not resolve parameter ${ref} under ${path}, so it cannot be checked.` });

    const tenantScoped = takesTenantHeader(ctx, pathItem.parameters, base, unresolved);

    for (const method of HTTP_METHODS) {
      const operation = resolveFrom(ctx, pathItem[method], base).node;
      if (!operation) continue;

      visit({
        path,
        method,
        operation,
        guarded:
          tenantScoped ||
          takesTenantHeader(ctx, operation.parameters, base, unresolved) ||
          path.startsWith(ADMIN_PREFIX),
      });
    }
  }
}

module.exports = function authz() {
  return {
    id: 'authz',
    rules: {
      oas3: {
        'x-authz-required': () => ({
          Root(root, ctx) {
            eachOperation(root, ctx, ({ path, method, operation, guarded }) => {
              if (!guarded || operation['x-authz']) return;
              ctx.report({
                message:
                  `${method.toUpperCase()} ${path} takes ${TENANT_HEADER} or lives under ` +
                  `${ADMIN_PREFIX} but declares no x-authz, so it would be reachable by ` +
                  'anyone signed in. Add one.',
              });
            });
          },
        }),
        'x-authz-permission-used': () => ({
          Root(root, ctx) {
            const schemas = (root.components || {}).schemas || {};
            const catalog = (resolveFrom(ctx, schemas.Permission, undefined).node || {}).enum || [];
            if (catalog.length === 0) return;

            const demanded = new Set();
            eachOperation(root, ctx, ({ operation }) => {
              const rule = operation['x-authz'];
              if (rule && rule.permission) demanded.add(rule.permission);
            });

            const unused = catalog.filter((permission) => !demanded.has(permission));
            if (unused.length > 0) {
              ctx.report({
                message:
                  'Permissions no operation requires: ' + unused.join(', ') +
                  '. Either an operation is missing its x-authz, or the catalog has an entry nothing uses.',
              });
            }
          },
        }),
      },
    },
  };
};
