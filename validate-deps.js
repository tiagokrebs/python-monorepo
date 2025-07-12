#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const toml = require('@iarna/toml');

class DependencyValidator {
  constructor(pyprojectPath) {
    this.config = this.loadConfig(pyprojectPath);
    this.approvedPackages = new Set(this.config.approved.map(dep => this.extractPackageName(dep)));
    this.internalPackages = this.discoverInternalPackages(path.dirname(pyprojectPath));
  }

  loadConfig(pyprojectPath) {
    try {
      const content = fs.readFileSync(pyprojectPath, 'utf-8');
      const pyproject = toml.parse(content);
      
      const deps = pyproject.tool?.monorepo?.dependencies;
      if (!deps) {
        throw new Error('No [tool.monorepo.dependencies] section found in pyproject.toml');
      }
      
      return deps;
    } catch (error) {
      console.error('Failed to load configuration:', error.message);
      process.exit(1);
    }
  }

  discoverInternalPackages(rootDir) {
    const packagesDir = path.join(rootDir, 'packages');
    const internalPackages = new Set();

    if (!fs.existsSync(packagesDir)) {
      return internalPackages;
    }

    const packageDirs = fs.readdirSync(packagesDir, { withFileTypes: true })
      .filter(dirent => dirent.isDirectory())
      .map(dirent => dirent.name);

    for (const packageDir of packageDirs) {
      const pyprojectPath = path.join(packagesDir, packageDir, 'pyproject.toml');
      if (fs.existsSync(pyprojectPath)) {
        try {
          const content = fs.readFileSync(pyprojectPath, 'utf-8');
          const parsed = toml.parse(content);
          const packageName = parsed.project?.name;
          if (packageName) {
            internalPackages.add(packageName);
          }
        } catch (error) {
          console.warn(`Could not parse ${pyprojectPath}: ${error.message}`);
        }
      }
    }

    return internalPackages;
  }

  extractPackageName(dependencyString) {
    if (dependencyString.includes(' @ ')) {
      return dependencyString.split(' @ ')[0].trim();
    }
    
    const operators = ['==', '>=', '<=', '>', '<', '~=', '!='];
    for (const op of operators) {
      if (dependencyString.includes(op)) {
        return dependencyString.split(op)[0].trim();
      }
    }
    
    return dependencyString.trim();
  }

  isDependencyAllowed(dependency) {
    const packageName = this.extractPackageName(dependency);
    
    // Check if it's an internal package (always allowed)
    if (this.internalPackages.has(packageName)) {
      return true;
    }

    // Check if it's in the approved list
    return this.approvedPackages.has(packageName);
  }

  validatePackage(packageDir) {
    const packageName = path.basename(packageDir);
    const pyprojectPath = path.join(packageDir, 'pyproject.toml');
    const packageJsonPath = path.join(packageDir, 'package.json');
    
    const result = {
      package: packageName,
      errors: [],
      dependencies: [],
      isValid: true
    };

    // Skip non-Python packages (Node.js packages with package.json but no pyproject.toml)
    if (!fs.existsSync(pyprojectPath) && fs.existsSync(packageJsonPath)) {
      result.isValid = true;
      result.skipped = true;
      result.reason = 'Non-Python package (Node.js/other)';
      return result;
    }

    if (!fs.existsSync(pyprojectPath)) {
      result.errors.push(`No pyproject.toml found in ${packageName}`);
      result.isValid = false;
      return result;
    }

    try {
      const content = fs.readFileSync(pyprojectPath, 'utf-8');
      const pyproject = toml.parse(content);

      // Check main dependencies
      const dependencies = pyproject.project?.dependencies || [];
      for (const dep of dependencies) {
        result.dependencies.push(dep);
        if (!this.isDependencyAllowed(dep)) {
          const depName = this.extractPackageName(dep);
          result.errors.push(`UNAPPROVED package '${dep}' found in ${packageName}`);
        }
      }

      // Check optional dependencies
      const optionalDeps = pyproject.project?.['optional-dependencies'] || {};
      for (const [group, deps] of Object.entries(optionalDeps)) {
        for (const dep of deps) {
          result.dependencies.push(`${dep} (optional-${group})`);
          if (!this.isDependencyAllowed(dep)) {
            const depName = this.extractPackageName(dep);
            result.errors.push(`UNAPPROVED package '${dep}' found in optional-dependencies.${group}`);
          }
        }
      }

    } catch (error) {
      result.errors.push(`Failed to parse ${pyprojectPath}: ${error.message}`);
    }

    result.isValid = result.errors.length === 0;
    return result;
  }

  validateAllPackages(rootDir) {
    console.log('Validating package dependencies...');

    const packagesDir = path.join(rootDir, 'packages');
    if (!fs.existsSync(packagesDir)) {
      console.error('packages/ directory not found');
      return false;
    }

    const packageDirs = fs.readdirSync(packagesDir, { withFileTypes: true })
      .filter(dirent => dirent.isDirectory())
      .map(dirent => path.join(packagesDir, dirent.name));

    if (packageDirs.length === 0) {
      console.log('No packages found in packages/ directory');
      return true;
    }

    let totalErrors = 0;

    for (const packageDir of packageDirs) {
      const result = this.validatePackage(packageDir);

      if (result.skipped) {
        console.log(`${result.package}: Skipped (${result.reason})`);
      } else if (result.isValid) {
        console.log(`${result.package}: All dependencies approved`);
      } else {
        console.log(`Package: ${result.package}`);
        if (result.dependencies.length > 0) {
          console.log(`  Dependencies found:`);
          for (const dep of result.dependencies) {
            console.log(`  - ${dep}`);
          }
        }
        console.log(`  Errors:`);
        for (const error of result.errors) {
          console.log(`  - ${error}`);
          totalErrors++;
        }
      }
    }

    console.log(`\nSummary: ${totalErrors} errors`);

    if (totalErrors === 0) {
      console.log('All packages have approved dependencies');
      return true;
    } else {
      console.log('Some packages have unapproved dependencies');
      return false;
    }
  }

  validateSinglePackage(rootDir, packageName) {
    console.log(`Validating package: ${packageName}`);

    const packagePath = path.join(rootDir, 'packages', packageName);
    if (!fs.existsSync(packagePath)) {
      console.error(`Package '${packageName}' not found in packages/ directory`);
      return false;
    }

    const result = this.validatePackage(packagePath);

    if (result.isValid) {
      console.log(`${result.package}: All dependencies approved`);
      if (result.dependencies.length > 0) {
        console.log(`Dependencies:`);
        for (const dep of result.dependencies) {
          console.log(`  - ${dep}`);
        }
      }
      console.log(`Package '${packageName}' has all approved dependencies`);
      return true;
    } else {
      if (result.dependencies.length > 0) {
        console.log(`Dependencies found:`);
        for (const dep of result.dependencies) {
          console.log(`  - ${dep}`);
        }
      }
      console.log(`Errors:`);
      for (const error of result.errors) {
        console.log(`  - ${error}`);
      }
      console.log(`Package '${packageName}' has unapproved dependencies`);
      return false;
    }
  }

  listApprovedDependencies() {
    console.log('Approved Dependencies:');

    console.log('\nInternal Packages (automatically allowed):');
    if (this.internalPackages.size > 0) {
      for (const pkg of Array.from(this.internalPackages).sort()) {
        console.log(`  ${pkg}`);
      }
    } else {
      console.log('  (none found)');
    }

    console.log('\nExternal Dependencies:');
    if (this.config.approved.length > 0) {
      for (const dep of this.config.approved.sort()) {
        console.log(`  ${dep}`);
      }
    } else {
      console.log('  (none configured)');
    }
  }
}

function main() {
  const args = process.argv.slice(2);
  const rootDir = process.cwd();
  const pyprojectPath = path.join(rootDir, 'pyproject.toml');

  if (!fs.existsSync(pyprojectPath)) {
    console.error('pyproject.toml not found in root directory');
    process.exit(1);
  }

  const validator = new DependencyValidator(pyprojectPath);

  if (args.includes('--list')) {
    validator.listApprovedDependencies();
    return;
  }

  const packageIndex = args.indexOf('--package');
  if (packageIndex !== -1 && args[packageIndex + 1]) {
    const packageName = args[packageIndex + 1];
    const isValid = validator.validateSinglePackage(rootDir, packageName);
    process.exit(isValid ? 0 : 1);
  } else {
    const isValid = validator.validateAllPackages(rootDir);
    process.exit(isValid ? 0 : 1);
  }
}

if (require.main === module) {
  main();
}
