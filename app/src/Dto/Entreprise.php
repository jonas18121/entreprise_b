<?php 

declare(strict_types=1);

namespace App\Dto;

use App\Dto\Siege;

/** 
 * Représente une entreprise de l'API Recherche d'entreprise
 */ 
class Entreprise 
{
    public function __construct(
        public readonly string $siren,
        public readonly string $nomComplet,
        public readonly ?string $nomRaisonSociale = null,
        public readonly ?Siege $siege = null,
        public readonly ?string $activitePrincipale = null,
        public readonly ?string $natureJuridique = null,
        public readonly ?string $dateCreation = null,
        public readonly ?string $etatAdministratif = null,
        public readonly ?int $nombreEtablissement = null,
        public readonly ?bool $estAssociation = null,
    )
    {
        
    }

    /** 
     * Permet à la classe de se créer lui même en objet en hydratant les bonnes données
     */ 
    public static function fromArray(array $data): self
    {
        $siege = isset($data['siege']) ? Siege::fromArray($data['siege']) : null;

        // Depuis PHP8 on peut utiliser cette syntaxe siret: ...
        return new self(
            siren: $data['siren'] ?? '',
            nomComplet: $data['nom_complet'] ?? '',
            nomRaisonSociale: $data['nom_raison_sociale'] ?? null,
            siege: $siege,
            activitePrincipale: $data['activite_principale'] ?? null,
            natureJuridique: $data['nature_juridique'] ?? null,
            dateCreation: $data['date_creation'] ?? null,
            etatAdministratif: $data['etat_administratif'] ?? null,
            nombreEtablissement: $data['nombre_etablissement'] ?? null,
            estAssociation: $data['est_association'] ?? null,
        );
    }

    public function isActif(): bool
    {
        return $this->etatAdministratif === 'A';
    }

    public function getCodeNaf(): ?string
    {
        return $this->activitePrincipale;
    }
}